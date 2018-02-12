from flask import Flask
from flask_restplus import Resource, Api
from flask_restplus import reqparse
from nltk import pos_tag
from nltk.tokenize import word_tokenize

app = Flask(__name__)
app.config['SWAGGER_UI_DOC_EXPANSION'] = 'list'
api = Api(app)
parser = reqparse.RequestParser()
parser.add_argument('inputString', type=str, required=True)


@api.route('/wsd', endpoint='wsd')
class HelloWorld(Resource):

    @api.expect(parser, validate=True)
    def get(self):
        args = parser.parse_args()
        inputString = args['inputString']
        return pos_tag(word_tokenize(inputString))


if __name__ == '__main__':
    app.run(debug=True)