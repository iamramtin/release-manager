# EC2 Deployment #
The server will then be hosted on [100.91.108.12:8000]() on the EC2, accessible only with the VPN.

Server port can be modified in the **app.py** file in src/API.

On the EC2, the following server file was made: **/etc/systemd/system/release-manager.service**

A Python virtual environment was made in src/API/venv. This, along with the service file, flask, and gunicorn are essential to hosting the flask application on the EC2.

The following packages are required:
* `pip3 install Flask`
* `pip3 install flask-restful`
* `pip3 install gunicorn`
* `yum install nginx`

You can host the server manually by running `python app.py` from within the src/API folder.

You can also run the server using gunicorn: `gunicorn -b 0.0.0.0:8000 app:app`.

For more information, see: https://medium.com/techfront/step-by-step-visual-guide-on-deploying-a-flask-application-on-aws-ec2-8e3e8b82c4f7

## Updating The Repo ##
If the repo is modified in any way, you will have to run the following for the changes to reflect:
* `sudo systemctl daemon-reload`
* `sudo systemctl stop release-manager`
* `sudo systemctl start release-manager`


# Local Deployment #
From within the src/API directory, run `python app.py`. The server will then be hosted on [localhost:8000]()

