# Einthusanlib

## Description

This script downloads movies listed in the popular section from the URL provided in the configuration file. It uses Nokogiri to parse the HTML content and youtube-dl to download the movies. The downloaded movies are saved in the specified directory and can be served using Caddy.

## Dependencies

- Ruby
- Nokogiri
- youtube-dl (you need Python and pip)

## How to Run the Script

1. Install the dependencies:
   ```sh
   gem install nokogiri
   pip install youtube-dl
   ```

2. Run the script:
   ```sh
   ruby main.rb
   ```

## Configuration

- The configuration settings are located in the `config.rb` file.
- Update the `URL`, `BASE_URL`, `DOWNLOAD_PATH`, and `LOG_FILE` constants as needed.

## How to Serve Using Caddy

1. Update the Caddyfile:
   ```sh
   vi /etc/caddy/Caddyfile
   ```

2. Add the following configuration:
   ```plaintext
   :80 {
       # Set this path to your site's directory.
       root * /home/eithusanlib/public/movies

       # Enable the static file server.
       file_server browse
   }
   ```

3. Reload Caddy:
   ```sh
   systemctl reload caddy
   ```

## How to Access the Website

1. Open your web browser.
2. Navigate to the server's IP address or domain name.
   ```plaintext
   http://<your-server-ip-or-domain>
   ```

## Additional Information

- Ensure the `public/movies` directory is writable.
- Logs are written to `einthusan.log`.

## Work in Progress

- This project is a work in progress. Contributions and suggestions are welcome.