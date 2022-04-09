# pip install paho-mqtt

import asyncio
import paho.mqtt.client as mqtt
import pandas as pd
import time
from datetime import date, datetime
import os
import json
import boto3
import awswrangler as wr

start_time = int(time.time())

def setup_client():
	user = "grupo2-bancadaB1"
	passwd = "L@Bdygy1B1"

	Broker = "labdigi.wiseful.com.br"            # Endereco do broker
	Port = 80                           # Porta utilizada (firewall da USP exige 80)
	KeepAlive = 60                      # Intervalo de timeout (60s)

	# Quando conectar na rede (Callback de conexao)
	def on_connect(client, userdata, flags, rc):
		print("Conectado com codigo " + str(rc))

		subs = ['hello', 'E0', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7',
				'S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7']
		for sub in subs:
			client.subscribe(f"grupo2-bancadaB1/{sub}", qos=0)

	# Quando receber uma mensagem (Callback de mensagem)
	def on_message(client, userdata, msg):

		current_datetime = datetime.now()
		current_topic = str(msg.topic)
		current_value = str(msg.payload.decode("utf-8"))
		client._my_messages.append({"topic": current_topic, "value": current_value, "time": current_datetime})
		# print(current_datetime)
		# print(current_topic)
		# print(current_value)
		# print("-- -- ")

	client = mqtt.Client()                      # Criacao do cliente MQTT
	client._my_messages = []
	client.on_connect = on_connect              # Vinculo do Callback de conexao
	client.on_message = on_message              # Vinculo do Callback de mensagem recebida
	client.username_pw_set(user, passwd)        # Apenas psara coneccao com login/senha
	client.connect(Broker, Port, KeepAlive)     # Conexao do cliente ao broker

	client.loop_start()

	return client

def save_df_to_s3(df):
	with open("keys.json", "r") as f:
		aws_keys = json.load(f)

	# create session
	session = boto3.Session(aws_access_key_id=aws_keys["access_key"], aws_secret_access_key=aws_keys["secret_key"])

	bucket_name = "labdigi-filebucket"
	# get timestamp in milliseconds using time.time_ns()
	timestamp = int(time.time_ns()/1000000)

	wr.s3.to_json(df=df, path=f"s3://labdigi-filebucket/raw_data/{start_time}/{timestamp}/data.json", boto3_session=session)


async def async_loop(client):
	counter = 0
	while True:
		print(f"-- Executando... {datetime.now()}")

		if counter == 1:
			print(f"Salvando mensagens...")

			if len(client._my_messages) == 0:
				print("Nenhuma mensagem recebida")

			else:
				print(client._my_messages)


				start_time = time.time_ns()
				
				# create copy of messages
				messages = client._my_messages.copy()
				client._my_messages = []

				df = pd.DataFrame.from_dict(messages)
				save_df_to_s3(df)

				end_time = time.time_ns()

				print("Demora para salvar o arquivo:", (end_time-start_time)/(10**6), "ms")


			counter = 0

		counter += 1
		# print(" -- ")
		await asyncio.sleep(5)

def delete_objects(since_time: int = 0) -> None:

	with open("keys.json", "r") as f:
		aws_keys = json.load(f)

	session = boto3.Session(aws_access_key_id=aws_keys["access_key"], aws_secret_access_key=aws_keys["secret_key"])

	objects = wr.s3.list_objects(f"s3://labdigi-filebucket/raw_data/", boto3_session=session)

	timestamps = [int(object_.split("/")[4]) for object_ in objects]

	df = pd.DataFrame([objects, timestamps]).T
	df.columns = ['paths', 'timestamps']
	df['datetime'] = pd.to_datetime(df['timestamps'], unit='ms')

	df = df[df['timestamps'] > since_time]

	objects_to_delete = list(df['paths'])

	wr.s3.delete_objects(objects_to_delete, boto3_session=session)


if __name__ == "__main__":
	# delete_objects()
	client = setup_client()
	asyncio.run(async_loop(client))