sudo cp favicon.ico /var/www/html/
sudo cp FIND_admin.html /var/www/html/
sudo cp FIND_client.html /var/www/html/
sudo cp style1.css /var/www/html/
sudo cp jquery.min.js /var/www/html/
sudo cp jquery.sidecontent.js /var/www/html/
sudo cp loader.gif /var/www/html/
sudo cp favicon.ico /usr/lib/cgi-bin
sudo cp "Linux CGI Files"/results_admin.cgi /usr/lib/cgi-bin/
sudo cp "Linux CGI Files"/results_client.cgi /usr/lib/cgi-bin/
sudo cp "Linux CGI Files"/dbdeleteadmin.cgi /usr/lib/cgi-bin/
sudo cp style1.css /usr/lib/cgi-bin/
sudo cp jquery.min.js /usr/lib/cgi-bin/
sudo cp loader.gif /usr/lib/cgi-bin/
sudo dos2unix /usr/lib/cgi-bin/results_admin.cgi
sudo dos2unix /usr/lib/cgi-bin/results_client.cgi
sudo dos2unix /usr/lib/cgi-bin/dbdeleteadmin.cgi
sudo chmod +x /usr/lib/cgi-bin/results_admin.cgi
sudo chmod +x /usr/lib/cgi-bin/results_client.cgi
sudo chmod +x /usr/lib/cgi-bin/dbdeleteadmin.cgi