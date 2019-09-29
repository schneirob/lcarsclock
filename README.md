~~~bash
sudo apt install bc imagemagick
~~~

~~~crontab
# m h  dom mon dow   command
* * * * * cd /home/pi/lcarsclock; ./lcarsclock.sh &> /dev/null
~~~
