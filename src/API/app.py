import json
import subprocess
import requests

from requests.auth import HTTPBasicAuth

from subprocess import check_output

from flask import Flask, request, jsonify
from flask_restful import Api

from http.client import HTTPSConnection
from base64 import b64encode

from jira import JIRA


app = Flask(__name__)
api = Api(app)

#################################################################
# GLOBAL PROPERTIES
#################################################################
scripts_dir = "../SCRIPTS/"


# INTERNAL API REQUESTS
#################################################################
@app.route("/")
def homepage():
    return "<h1>Release Manager API</h1>"


@app.after_request
def after_request(response):
    header = response.headers
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    header['Access-Control-Allow-Methods'] = 'OPTIONS, HEAD, GET, POST, DELETE, PUT'

    return response


@app.route("/hello-world", methods=["GET"])
def hello_world():
    return jsonify(
        response="Success: hello, world!",
    )


@app.route("/create-note", methods=["GET"])
def create_note():
    json_data = request.values.to_dict()

    output = str(check_output(["sh", "./" + scripts_dir + "create_note.sh", str(json_data)]))
    resp_dict = clean_dict(output)
    response = {"repo_name": resp_dict[0], "note_name": resp_dict[1]}

    return jsonify(
        status="successful",
        response=response,
    )


@app.route("/list-uncollated-notes", methods=["GET"])
def list_uncollated_notes():
    output = str(check_output(["sh", "./" + scripts_dir + "list_uncollated_notes.sh"]))
    response = output[2:len(output) - 5] + "]}"
    response = response.replace('\\n', '')

    return response


# TODO
@app.route("/collate-notes", methods=["GET", "POST"])
def collate_notes():
    version = request.values.get("version")
    date = request.values.get("date")
    notes = request.values.get("notes")

    # Example:
    # version = "5.4.0"
    # date = "2022-06-02"
    # notes = [
    #     "repo_one/2021-08-22_5f91f71_SR-55225.html",
    #     "repo_two/2021-09-22_5f91f71_SR-55225.html",
    #     "repo_three/2021-09-08_6afcf8b_FIN-1799.html",
    #     "repo_four/2022-01-07_d20d141.html"
    # ]

    subprocess.check_call(["sh", "./" + scripts_dir + "collate_notes.sh", version, date, str(notes)])

    return jsonify(
        status="successful",
    )


@app.route("/create-release-branches", methods=["POST"])
def create_release_branches():
    version = request.values.get("version")
    branch = request.values.get("base_branch")

    subprocess.check_call(["sh", "./" + scripts_dir + "create_release_branches.sh", version, branch])

    return jsonify(
        response="Release branches created",
    )


@app.route("/merge-release-branches", methods=["POST"])
def merge_release_branches():
    from_branch = request.values.get("from_branch")
    to_branch = request.values.get("to_branch")

    subprocess.check_call(["sh", "./" + scripts_dir + "merge_release_branches.sh", from_branch, to_branch])

    return jsonify(
        response="Release branches merged",
    )


@app.route("/lock-release-branch", methods=["POST"])
def lock_release_branch():
    lock_branch = request.values.get("lock_branch")

    subprocess.check_call(["sh", "./" + scripts_dir + "lock_release_branch.sh", lock_branch])

    return jsonify(
        response="Release branches locked",
    )


# BITBUCKET REST API 2.0
#################################################################
@app.route("/get-git-commits", methods=["GET"])
def get_git_commits():
    url = "api.bitbucket.org"
    # repo = request.values.get("repo")
    repo = "txstream"
    team = "admin"
    url_body = "/2.0/repositories/%s/%s/commits?start=0&size=3&limit=3" % (team, repo)
    username = "testuser"
    # password = "ySWey4gCGSMza9Aw3cuF" # FULL ACCESS
    password = "ATBBUY5NtDB7aWhNScJ6ZCEJBTPA5A8D403B" # READ ONLY

    connection = HTTPSConnection(url)

    # base 64 encode then decode to ascii
    basic_auth = "Basic " + b64encode((username + ":" + password).encode()).decode("ascii")
    headers = {"Authorization": basic_auth}

    connection.request("GET", url_body, headers=headers)
    resp = json.loads(connection.getresponse().read())
    data = list(resp['values'])

    commit_list = {}
    filter_list_size = len(data)
    for i in range(filter_list_size):
        commit_list["commit_" + str(i)] = {
            "author": data[i]['author']['raw'],
            "hash": data[i]['hash'],
            "message": data[i]['message'],
            "repo": data[i]['repository']['name'],
        }

    return commit_list


# JIRA REST API 2.0
#################################################################
@app.route("/get-jira-ticket", methods=["GET"])
def get_jira_data():
    email = "user@test.com"
    api_key = "5RFrf8y2Wr1cYck4jwBi4BCD"
    ticket_id = "SRM-3"
    url = "https://project_name.atlassian.net/rest/api/3/issue/{}?expand=names".format(ticket_id)

    auth = HTTPBasicAuth(email, api_key)
    headers = {
        "Accept" : "application/json"
    }

    response = requests.request(
        "GET",
        url,
        headers=headers,
        auth=auth
    )

    json_data = json.dumps(json.loads(response.text), sort_keys=True, indent=4, separators=(",", ": "))

    return "<html><body><pre><code>" + json_data + "</code></pre></body></html>"


# TODO
def get_jira_field_data():
    print("do something here")

    # get-jira-ticket api call to get jira ticket data
    # manipulate data to get the following:
        # 1. iterate through custom fields
        # 2. filter out nulls and empties and random unnecessary fields
        # 3. get name of field that we want using its unique custom field id
        # 4. get data from its body and the different data types (such as item list, text, imafe, heading, etc.)


@app.route("/get-jira-data-test", methods=["GET"])
def get_jira_data_test():
    email = "user@test.com"
    api_key = "5RFrf8y2Wr1cYck4jwBi4BCD"
    url = "https://project_name.atlassian.net/rest/api/3/issue/SRM-3?expand=names"

    auth = HTTPBasicAuth(email, api_key)
    headers = {
        "Accept" : "application/json"
    }

    response = requests.request(
        "GET",
        url,
        headers=headers,
        auth=auth
    )

    json_data = json.loads(response.text)
    # json_str = json.dumps(json_data, sort_keys=True, indent=4, separators=(",", ": "))

    # example: some logic to filter through null fields such as customfield_12021 versus those with content
    print(json_data["fields"]["customfield_12019"])
    if json_data["fields"]["customfield_12019"] is None:
        print("Is None")
    else:
        print("Not None")
    print(type(json_data["fields"]["customfield_12019"]))

    json_str = json.dumps(json_data["fields"]["customfield_12019"], sort_keys=True, indent=4, separators=(",", ": "))
    return "<html><body><pre><code>" + json_str + "</code></pre></body></html>"



#################################################################
# FUNCTIONS
#################################################################
def save_file(file_path, data):
    file = open(file_path, "w")
    file.write(str(data))
    file.close()


    # returns name of repo and note as a dict
def clean_dict(resp):
    resp = resp[2:len(resp) - 3]
    return resp.split("/")


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000)
