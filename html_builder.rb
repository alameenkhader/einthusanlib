# frozen_string_literal: true

require 'fileutils'
require_relative 'config'

HTML_FILE_PATH = "#{DOWNLOAD_PATH}/index.html"

def teardown_html_page
  LOGGER.info 'Tearing down HTML page'

  if File.exist?(HTML_FILE_PATH)
    LOGGER.info "Removing HTML file: #{HTML_FILE_PATH}"
    FileUtils.rm(HTML_FILE_PATH)
  else
    LOGGER.info "HTML file does not exist: #{HTML_FILE_PATH}"
  end
end

def build_html_page(media_list)
  LOGGER.info 'Building HTML page'

  # Create directory if it doesn't exist/
  FileUtils.mkdir_p(File.dirname(HTML_FILE_PATH))

  html_content = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Chalaflix</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {
      background-color: #121212;
      color: #f5f5f5;
    }
    .media-card {
      height: 100%;
      transition: transform 0.3s ease;
      background-color: #1e1e1e;
      border-color: #333;
    }
    .media-card:hover {
      transform: scale(1.05);
      box-shadow: 0 10px 20px rgba(0,0,0,0.5);
    }
    .media-link {
      color: #f5f5f5;
      text-decoration: none;
      display: block;
    }
    .media-link:hover {
      color: #f5f5f5;
      text-decoration: none;
    }
    .media-img {
      object-fit: cover;
    }
    .card-title {
      margin-bottom: 0.5rem;
      color: #f5f5f5;
    }
    .file-name {
      font-size: 0.8rem;
      color: #adb5bd;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .container h1 {
      color: #f5f5f5;
    }
  </style>
</head>
<body>
  <div class="container py-5">
    <div class="text-center mb-4">
      <img src="../banner.png" alt="Banner" class="img-fluid p-3" style="max-width: 500px;">
    </div>

    <div class="row row-cols-2 row-cols-md-2 row-cols-lg-3 g-4">
  HTML

  media_list.each do |media|
    html_content += <<-HTML
      <div class="col">
        <div class="card media-card">
          <a href="./#{media[:file_name]}" class="media-link">
            <img src="#{media[:image_url]}" class="card-img-top media-img" alt="#{media[:title]}">
            <div class="card-body">
              <h5 class="card-title">#{media[:title]}</h5>
              <p class="file-name">#{media[:file_name]}</p>
            </div>
          </a>
        </div>
      </div>
    HTML
  end

  html_content += <<-HTML
    </div>
  </div>

  <footer class="bg-dark text-light text-center py-3 mt-5">
    <div class="container">
      <p class="mb-0">Last updated: #{Time.now.strftime('%B %d, %Y at %H:%M %Z')}</p>
    </div>
  </footer>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
  HTML

  File.write(HTML_FILE_PATH, html_content)
  LOGGER.info "HTML page built successfully: #{HTML_FILE_PATH}"
end
