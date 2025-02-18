# Einthusanlib

## Description

This script downloads movies listed in the popular section from the URL provided in the configuration file. It uses Nokogiri to parse the HTML content and youtube-dl to download the movies. The downloaded movies are saved in the specified directory and can be served using a file server like Caddy.

## Dependencies

- Ruby
- Nokogiri
- youtube-dl (you need Python and pip)
- Logger (Ruby standard library)
- Caddy (for serving the downloaded movies)

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

## How to Install Caddy

### On Mac

1. Install Caddy using Homebrew:
   ```sh
   brew install caddy
   ```

### On Linux

1. Update the package list and install Caddy:
   ```sh
   sudo apt update
   sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo apt-key add -
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
   sudo apt update
   sudo apt install caddy
   ```

For more detailed installation instructions, visit the [Caddy website](https://caddyserver.com/docs/install).

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

## Setting Up a Cron Job

To run the script every day at midnight, set up a cron job:

1. Open the crontab file for editing:
   ```sh
   crontab -e
   ```

2. Add the following line to schedule the script to run every day at midnight:
   ```plaintext
   0 0 * * * cd /Users/alameenkhader/einthusanlib && /usr/bin/ruby main.rb
   ```

3. Save and close the crontab file.

## Viewing Cron Logs

To view the logs for cron jobs, use the following command:
   ```sh
   grep CRON /var/log/syslog
   ```

## Additional Information

- Ensure the `public/movies` directory is writable.
- Logs are written to `einthusan.log`.

## Work in Progress

- This project is a work in progress.

## Disclaimer

- This project is for educational purposes only. The author is not responsible for any privacy issues or misuse of this script.

