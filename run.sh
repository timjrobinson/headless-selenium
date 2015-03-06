#!/bin/sh
set -e
set -x

SELENIUM_VERSION="2.45.0"
SELENIUM_PORT="4444"
CHROME_VERSION=$(curl http://chromedriver.storage.googleapis.com/LATEST_RELEASE)

while test $# -gt 0; do
  case "$1" in
    -p|-port|--port)
      shift
      SELENIUM_PORT=$1
      shift
      ;;
    *)
      break
      ;;
  esac
done
                  
                
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -e /.installed ]; then
  echo 'Already installed.'

else
  echo ''
  echo 'INSTALLING'
  echo '----------'

  # Add Google public key to apt
  wget -q -O - "https://dl-ssl.google.com/linux/linux_signing_key.pub" | sudo apt-key add -

  # Add Google to the apt-get source list
  echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list

  # Update app-get
  apt-get update

  # Install Java, Chrome, Xvfb, and unzip
  apt-get -y install openjdk-7-jre google-chrome-stable xvfb unzip

  # Download and copy the ChromeDriver to /usr/local/bin
  cd /tmp
  wget "http://chromedriver.storage.googleapis.com/${CHROME_VERSION}/chromedriver_linux64.zip"
  wget "http://selenium-release.storage.googleapis.com/${SELENIUM_VERSION%??}/selenium-server-standalone-${SELENIUM_VERSION}.jar"
  unzip chromedriver_linux64.zip
  mv chromedriver /usr/local/bin
  mv selenium-server-standalone-${SELENIUM_VERSION}.jar /usr/local/bin

  # So that when we run this again it doesn't download everything. 
  touch /.installed
fi

# Start Xvfb, Chrome, and Selenium in the background
export DISPLAY=:10

echo "Starting Xvfb ..."
Xvfb :10 -screen 0 1366x768x24 -ac &

echo "Starting Google Chrome ..."
google-chrome --remote-debugging-port=9222 &

echo "Starting Selenium ..."
cd /usr/local/bin
nohup java -jar ./selenium-server-standalone-${SELENIUM_VERSION}.jar -port $SELENIUM_PORT &
