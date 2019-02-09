from flask import Flask, request, jsonify
from flask_cors import CORS
import sudoku as s

app = Flask(__name__)
CORS(app)

def build_puzzle(blanks=45):
	g = s.sudoku()
	p, x = g.create_puzzle(num_blanks=blanks)
	pl = p.to_list()
	xl = x.to_list()
	js = {'to_solve':pl, 'solved':xl}
	return jsonify(js)


@app.route('/')
def api_root():
    return 'Welcome'

@app.route('/puzzle', methods=['GET', 'OPTIONS'])
def api_puzzle():
    if request.method=='GET':
        if 'blanks' in request.args:
            return build_puzzle(blanks=int(request.args['blanks']))
        else:
            return build_puzzle()
    elif request.method=='OPTIONS':
        pass


if __name__ == '__main__':
    app.run()
    #print(build_puzzle(blanks=1))
