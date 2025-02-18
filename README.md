# Einthusan Movie Downloader

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

## Additional Information

- Ensure the `public/movies` directory is writable.
- Logs are written to `einthusan.log`.