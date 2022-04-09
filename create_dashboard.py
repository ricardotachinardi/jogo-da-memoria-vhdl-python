import awswrangler as wr
import pandas as pd
import os
import boto3
import plotly.express as px
import plotly.graph_objects as go
import time

import json
with open("keys.json", "r") as f:
	aws_keys = json.load(f)

max_file_timestamp = 0
old_data_df = pd.DataFrame()
bucket_name = "labdigi-filebucket"


def get_files_df():
	# create session
	session = boto3.Session(aws_access_key_id=aws_keys["access_key"], aws_secret_access_key=aws_keys["secret_key"])

	files = wr.s3.list_objects(f"s3://{bucket_name}/raw_data/", boto3_session=session)
	df = pd.DataFrame(files, columns=['path'])

	df['timestamp'] = df['path'].apply(lambda x: int(x.split("/")[-2]))

	df['datetime'] = pd.to_datetime(df['timestamp'], unit='ms')

	df['folder_timestamp'] = df['path'].apply(lambda x: int(x.split("/")[-3]))

	df['folder_timestamp'].value_counts()

	#df = df[df['folder_timestamp'] == df['folder_timestamp'].max()]
	df = df[df['folder_timestamp'] == 1649259351]

	return df


def get_data_df():
	global max_file_timestamp
	global old_data_df

	session = boto3.Session(aws_access_key_id=aws_keys["access_key"], aws_secret_access_key=aws_keys["secret_key"])

	files_df = get_files_df()

	files_df = files_df[files_df['timestamp'] > max_file_timestamp]
	max_file_timestamp = files_df['timestamp'].max()

	files = list(files_df['path'])

	list_of_dfs = []
	for file in files:
		tmp_df = wr.s3.read_json(file, boto3_session=session)
		list_of_dfs.append(tmp_df)
	if len(list_of_dfs) > 0:
		data_df: pd.DataFrame = pd.concat(list_of_dfs)
		data_df = pd.concat([old_data_df, data_df], ignore_index=True, axis=0)
		old_data_df = data_df
	else:
		data_df = old_data_df


	return data_df


def process_data_df(df):
	df.reset_index(drop=True, inplace=True)
	df['time']=  df['time']*1000
	df['datetime'] =  pd.to_datetime(df['time'], unit='us')
	tmp_df = df[df.duplicated(subset=['topic', 'time'], keep=False)]

	topics_times = tmp_df[['topic', 'time']].drop_duplicates()
	topics_ = list(tmp_df['topic'])
	times_ = list(tmp_df['time'])

	# move os tempos alguns milisegundos para cima ou para baixo
	for topic_, time_ in zip(topics_, times_):
		values_to_replace = []
		filtered_df = tmp_df[(tmp_df['topic'] == topic_) & (tmp_df['time'] == time_)]

		max_ = len(filtered_df)
		print("-- Topic:", topic_, "Time:", time_, "Max:", max_)
		for i in range(max_):
			index = filtered_df.iloc[i].name
			if i < max_/2:
				print((max_-i+1)*-1)
				df['time'][index] = filtered_df.iloc[i]['time'] + (max_-i+1)*-1
			if i == max_/2:
				print(0)
				df['time'][index] = filtered_df.iloc[i]['time'] + 0
			if i > max_/2:
				print((i+1)*1)
				df['time'][index] = filtered_df.iloc[i]['time'] + (i+1)*1

	list_of_dfs = []
	for topic in list(df['topic'].unique()):
		print(topic)
		tmp_df = pd.pivot(df[df['topic'] == topic], columns=['topic'], index=['time'], values=['value'])
		list_of_dfs.append(tmp_df)

	for i in range(len(list_of_dfs)):
		list_of_dfs[i] = list_of_dfs[i]['value']

	# import reduce from functools
	from functools import reduce
	merged_df = reduce(lambda  left,right: pd.merge(left,right,left_index=True, right_index=True, how='outer'), list_of_dfs)

	merged_df = merged_df.sort_index().ffill()

	merged_df = merged_df.set_index(pd.to_datetime(merged_df.index, unit='us'), drop=True)

	df2 = df
	df = df[df['topic'] !='grupo2-bancadaB1/hello']

	df = df.set_index(pd.to_datetime(df['time'], unit='us'), drop=True)

	return df, df2, merged_df


def get_cleaned_df(df, topic, time_window='250ms'):
	tmp0 = df[(df['topic'] == topic) & (df['value'] == '0')].resample(time_window).first().dropna()
	tmp1 = df[(df['topic'] == topic) & (df['value'] == '1')].resample(time_window).first().dropna()
	return pd.concat([tmp0, tmp1], axis=0).sort_index()


def get_tmp_concat(df):
	tmp = get_cleaned_df(df, 'grupo2-bancadaB1/S4')

	if tmp.iloc[0]['value'] == '0':
		tmp = tmp.iloc[1:]

	# is even
	if len(tmp) % 2 == 0:
		pass
	# is odd
	else:
		tmp = tmp.iloc[0:len(tmp)-1]

	tmp1 = tmp[tmp['value'] == '1']['datetime']
	tmp0 = tmp[tmp['value'] == '0']['datetime']

	tmp1.reset_index(drop=True, inplace=True)
	tmp1.name = 'datetime_1'

	tmp0.reset_index(drop=True, inplace=True)
	tmp0.name = 'datetime_0'

	tmp_concat = pd.concat([tmp1, tmp0], axis=1)

	tmp_concat['timedelta'] = (tmp_concat['datetime_0']-tmp_concat['datetime_1']).dt.total_seconds()

	return tmp_concat


def get_modos_jogo_escolhidos(df):

	tmp_concat = get_tmp_concat(df)
	modos_jogo_escolhidos = []
	for i in range(len(tmp_concat)):
		try:
			sliced_df = df[(df['datetime'] > tmp_concat['datetime_1'].iloc[i]) & (df['datetime'] < tmp_concat['datetime_0'].iloc[i])]
			sliced_df = sliced_df[sliced_df['topic'].isin(['grupo2-bancadaB1/E3', 'grupo2-bancadaB1/E4', 'grupo2-bancadaB1/E5', 'grupo2-bancadaB1/E6'])]
			topic = sliced_df[sliced_df['value'] == '1']['topic'].iloc[0]
			datetime_ = sliced_df[sliced_df['value'] == '1']['datetime'].iloc[0]
			modos_jogo_escolhidos.append({'topic': topic, 'datetime': datetime_, 'num': i+1})
		except:
			modos_jogo_escolhidos.append({'topic': None, 'datetime': None, 'num': i+1})
	
	return modos_jogo_escolhidos


def plot_modos_jogo(df):
	modos = pd.DataFrame(get_modos_jogo_escolhidos(df))

	modos['label'] = modos['topic'].apply(lambda x: "Erro no jogo" if x is None else "Modo 1" if "E3" in x else "Modo 2" if "E4" in x else "Modo 3" if "E5" in x else "Modo 4")

	modos = modos[['datetime', 'label']]

	modos.columns = ['time', 'label']

	fig = go.Figure(data=[go.Table(
		header=dict(values=list(modos.columns),
					fill_color='grey',
					line_color='darkslategray',
					font={'color': 'white'},
					align='center'),
		cells=dict(values=[modos.time, modos.label],
				fill_color='lightgrey',
				align='center',
				line_color='darkslategray',
				font={'color': 'black'}
				)
				)
		])

	return fig


def plot_stats_jogo(df):

	statistics = pd.DataFrame(get_tmp_concat(df)['timedelta'].describe()).reset_index()
	statistics.columns = ['description', 'value']

	fig = go.Figure(data=[go.Table(
		header=dict(values=list(statistics.columns),
					fill_color='grey',
					line_color='darkslategray',
					font={'color': 'white'},
					align='center'),
		cells=dict(values=[statistics.description, statistics.value],
				fill_color='lightgrey',
				align='center',
				line_color='darkslategray',
				font={'color': 'black'}
				)
				)
		])

	return fig


def plot_pie_vitoriasxderrotas(df):
	derrotas = get_cleaned_df(df, 'grupo2-bancadaB1/S7', time_window='2s')
	num_derrotas = len(derrotas[derrotas['value'] == '1'])


	vitorias = get_cleaned_df(df, 'grupo2-bancadaB1/S6', time_window='5s')
	num_vitorias = len(vitorias[vitorias['value'] == '1'])

	labels = ['Vitórias', 'Derrotas']
	values = [num_vitorias, num_derrotas]
	fig = go.Figure(data=[go.Pie(labels=labels, values=values)])
	fig.update_layout(title_text="Vitórias x Derrotas")

	return fig


def plot_table_vitoriasxderrotas(df):
	vitorias = get_cleaned_df(df, 'grupo2-bancadaB1/S6', time_window='5s')
	vitorias = vitorias[vitorias['value'] == '1']
	derrotas = get_cleaned_df(df, 'grupo2-bancadaB1/S7', time_window='2s')
	derrotas = derrotas[derrotas['value'] == '1']
	jogos = pd.concat([vitorias, derrotas], axis=0).sort_index(ascending=False)
	jogos['label'] = jogos['topic'].apply(lambda x: "vitória" if x == 'grupo2-bancadaB1/S6'else "derrota")
	jogos = jogos['label'].reset_index()
	
	fig = go.Figure(data=[go.Table(
		header=dict(values=list(jogos.columns),
					fill_color='grey',
					line_color='darkslategray',
					font={'color': 'white'},
					align='center'),
		cells=dict(values=[jogos.time, jogos.label],
				fill_color='lightgrey',
				align='center',
				line_color='darkslategray',
				font={'color': 'black'}
				)
				)
	])

	return fig


def plot_scatter_vitoriasxderrotas(df):
	vitorias = get_cleaned_df(df, 'grupo2-bancadaB1/S6', time_window='5s')
	vitorias = vitorias[vitorias['value'] == '1']
	derrotas = get_cleaned_df(df, 'grupo2-bancadaB1/S7', time_window='2s')
	derrotas = derrotas[derrotas['value'] == '1']
	jogos = pd.concat([vitorias, derrotas], axis=0).sort_index(ascending=False)
	jogos['label'] = jogos['topic'].apply(lambda x: "vitória" if x == 'grupo2-bancadaB1/S6'else "derrota")
	jogos = jogos['label'].reset_index()
	
	fig = px.scatter(jogos, x='time', y='label', color='label', title='Vitórias x Derrotas')

	return fig


def plot_hello_rodadas(df, df2):

	rodadas = get_cleaned_df(df, 'grupo2-bancadaB1/S5')
	num_rodadas = len(rodadas[rodadas['value'] == '1'])

	num_rodadas

	hellos = df2[df2['topic'] == 'grupo2-bancadaB1/hello']
	num_hellos = len(hellos)

	num_hellos

	fig = go.Figure()

	fig.add_trace(go.Indicator(value=num_rodadas, title={'text': 'Número de Rodadas'}, domain = {'row': 0, 'column': 0}))

	fig.add_trace(go.Indicator(value=num_hellos, title={'text': 'Número de Hellos'}, domain = {'row': 1, 'column': 0}))

	fig.update_layout(
		grid = {'rows': 2, 'columns': 1, 'pattern': "independent"})

	return fig

# upload files to s3
def upload_file(file_name, bucket, object_name=None):
	"""Upload a file to an S3 bucket

	:param file_name: File to upload
	:param bucket: Bucket to upload to
	:param object_name: S3 object name. If not specified then file_name is used
	:return: True if file was uploaded, else False
	"""

	# If S3 object_name was not specified, use file_name
	if object_name is None:
		object_name = file_name

	# Upload the file
	session = boto3.Session(aws_access_key_id=aws_keys["access_key"], aws_secret_access_key=aws_keys["secret_key"])

	s3_client = session.client('s3')
	try:
		response = s3_client.upload_file(file_name, bucket, object_name)
	except:
		return False
	return True

def main():
	while True:
		df = get_data_df()

		df, df2, merged_df = process_data_df(df)

		fig = plot_modos_jogo(df)
		fig.write_html("output/modos_jogo.html")
		upload_file("output/modos_jogo.html", bucket=bucket_name)

		fig = plot_stats_jogo(df)
		fig.write_html("output/stats_jogo.html")
		upload_file("output/stats_jogo.html", bucket=bucket_name)

		fig = plot_pie_vitoriasxderrotas(df)
		fig.write_html("output/pie_vitoriasxderrotas.html")
		upload_file("output/pie_vitoriasxderrotas.html", bucket=bucket_name)

		fig = plot_table_vitoriasxderrotas(df)
		fig.write_html("output/table_vitoriasxderrotas.html")
		upload_file("output/table_vitoriasxderrotas.html", bucket=bucket_name)

		fig = plot_scatter_vitoriasxderrotas(df)
		fig.write_html("output/scatter_vitoriasxderrotas.html")
		upload_file("output/scatter_vitoriasxderrotas.html", bucket=bucket_name)

		fig = plot_hello_rodadas(df, df2)
		fig.write_html("output/hello_rodadas.html")
		upload_file("output/hello_rodadas.html", bucket=bucket_name)

		time.sleep(2)

if __name__ == '__main__':
	main()