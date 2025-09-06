require 'logger'

URLS = [
  'https://einthusan.tv/movie/results/?find=Recent&lang=malayalam',
  'https://einthusan.tv/movie/results/?find=Popularity&lang=malayalam&ptype=view&tp=l30d',
  # 'https://einthusan.tv/movie/results/?find=Popularity&lang=tamil&ptype=view&tp=l30d'
]
BASE_URL = 'https://einthusan.tv'
DOWNLOAD_PATH = 'public/movies'
LOG_FILE = 'main.log'
LOGGER = Logger.new(LOG_FILE)
DAYS_TO_KEEP_OLD_DOWNLOADS = 14

