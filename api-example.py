#!flask/bin/python

# Imports
import requests
import json
from requests.auth import HTTPBasicAuth
from flask import Flask, jsonify
from flask_httpauth import HTTPBasicAuth as HTTPBasicAuthLocal

app = Flask(__name__)
auth = HTTPBasicAuthLocal()

# Get JSON file config for our secrets.  This file will be deployed to the Docker Container through Jenkins.
with open("secrets.txt", "r") as json_file:
    print(json_file)
    data = json.load(json_file)

# Import Secrets into session variables
jiraAccount = data["JIRAACCOUNT"]
jiraApiKey = data['JIRAAPIKEY']
localAccount = data['LOCALACCOUNT']
localApiKey = data['LOCALAPIKEY']

# Construct user Data
USER_DATA = {
    localAccount: localApiKey
}

# Function to verify API call password
@auth.verify_password
def verify(username, password):
    if not (username and password):
        return False
    # Internal password verification code redacted
    return valid

# Define our only route for returning user UPN based on AccountId
@app.route('/api/upn/<accountId>', methods=['GET'])
@auth.login_required
def get_upn(accountId):
    query = requests.get('**************************' + accountId, auth=HTTPBasicAuth(jiraAccount,jiraApiKey))
    
    # Define our variable for populating JSON data into a dictionary object
    queryjson = lambda:None
    queryjson.__dict__ = json.loads(query.content)


    # Return our payload containing only the email address
    try:
        return queryjson.emailAddress.split('@')[0]
    except:
        response = jsonify('User Not Found')
        response.status_code = query.status_code
        return response

# Debugging (Change "debug" to "False" in production)
if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0')