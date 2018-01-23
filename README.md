# peka
Nerdish toy for inhabitants of Poznań using public transport.

No complaints accepted, use it at your own risk. ( ͡° ͜ʖ ͡°)

### Installation

```
git clone git@github.com:vincentvanbush/peka.git
cd peka
sudo ln -s `pwd`/peka.rb /usr/local/bin/peka
```
...or whatever you want to use for easy execution.

### Usage
Pass the line number, your source stop and your destination stop (or simply a prefix of their names) as command line arguments to get your departure time.
```
spurdo@sparde:~/peka (master)$ peka 14 łaz kurp
14 Rynek Łazarski -> Os. Sobieskiego odjeżdża za 3 minut
```
