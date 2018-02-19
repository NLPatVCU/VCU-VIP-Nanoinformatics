from flask import Flask, request
from flask_restplus import Resource, Api
from API.wsd import wsd
import json

app = Flask(__name__)
api = Api(app)

"""Post operation of WSD endpoint for API

Operation takes input in the following format:

{
   "target_word": <Word>,
   "target_word_start": <Word Start>,
   "context": <Context>,
   "possible_cuis": [
          <CUI>,
          <CUI>,
          <CUI>
   ]
}

Example call:

{
   "target_word": "ace",
   "target_word_start": 33,
   "context": "Evidence that the addition of an ACE inhibitor.",
   "possible_cuis": [
          "C0001044",
          "C0000111",
          "C4082138"
   ]
}
"""
@api.route('/wsd', endpoint='wsd')
class WSD(Resource):

    def post(self):
        data = request.get_json()
        data = json.dumps(data)
        return wsd(data)


if __name__ == '__main__':
    app.run(debug=True)

