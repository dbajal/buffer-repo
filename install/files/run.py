# coding=utf-8                                      
from flask import Flask                             
import socket                                       

app = Flask(__name__)                               

@app.route("/")                                                                                                                                                                              
def test_print():                                                                                                                                                                           
    content = u"<html><body><p>I'm black</p></body></html>"
    return content


if __name__ == "__main__":
    app.run('0.0.0.0', 80)
