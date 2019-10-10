~~~bash
sudo apt install bc imagemagick fortunes
~~~

~~~fortune
first fortune
%
second fortune
%
multi
line
fortune
%
~~~

~~~bash
strfile fortunefile
~~~

~~~crontab
# m h  dom mon dow   command
* * * * * cd /home/pi/lcarsclock; ./lcarsclock.sh &> /dev/null
~~~
