#Built-in modules
import os, boto3, json, base64, time

#Thirds party modules
from datetime import date
from flask import Flask, request, jsonify, render_template, redirect, url_for
from flask_bootstrap import Bootstrap5


# Get env variables for aws resources
API_GW = os.environ.get("API_GW")
S3_ARN = os.environ.get("CDN_ARN")
BACKEND_FUNCTION_NAME = os.environ.get("BACKEND_FUNCTION_NAME")
EMAIL_FUNCTION_NAME = os.environ.get("EMAIL_FUNCTION_NAME")

#Setup flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = '8BYkEfBA6O6donzWlSihBXox7C0sKR6b'

app.config['SERVER_NAME'] = API_GW
app.config['APPLICATION_ROOT'] = '/'
app.config['PREFERRED_URL_SCHEME'] = 'https'

Bootstrap5(app)

@app.route('/')
def get_all_posts():
    # TODO GET ALL POSTS FROM DB
  
    get_lambda_client = boto3.client('lambda')
            
    payload = {
                "action": "get_all"
            }
    
    response = get_lambda_client.invoke(
        FunctionName=BACKEND_FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    posts =  json.loads(response['Payload'].read().decode('utf-8'))
    posts = json.loads(posts.get("body"))
    
    print(type(posts))
    print(f"Posts: {posts}")

    for post in posts:
        print(type(post))
        print(post.get("id"))
    
    return render_template("index.html", all_posts=posts, current_user=0,  S3_ARN = S3_ARN)

# Route to get an specific post
@app.route("/post/<int:post_id>", methods=["GET", "POST"])
def show_post(post_id):
    get_lambda_client = boto3.client('lambda')
            
    payload = {
                "action": "get_one",
                "item": {
                    "id":f"{post_id}"
                }
            }
    
    response = get_lambda_client.invoke(
        FunctionName=BACKEND_FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    post =  json.loads(response['Payload'].read().decode('utf-8'))
    post = json.loads(post.get("body"))
    return render_template("post.html", post=post, current_user=0,  S3_ARN = S3_ARN)

# Route to add a post
@app.route("/newpost", methods=["GET", "POST"])
def add_post():
    if request.method == "GET":
        return render_template("make-post.html",  S3_ARN = S3_ARN)
    elif request.method == "POST":
        # Retrieve form data from the POST request
        try:
            print(request)
            title = request.form.get('title')
            subtitle = request.form.get('subtitle')
            image_url = request.form.get('image_url')
            content = request.form.get('content')

            # For demonstration purposes, print the form data
            print(f'Title: {title}, Subtitle: {subtitle}, Image URL: {image_url}, Content: {content}')

            # Handle the post and return a response
            #return redirect(url_for("get_all_posts"))
            
            post_lambda_client = boto3.client('lambda')
            
            payload = {
                "action": "put",
                "item": {
                    "id": f"{int(time.time())}",
                    "title": title,
                    "subtitle": subtitle,
                    "image_url": image_url,
                    "content": content,
                    "author": "user",
                    "date": date.today().strftime("%Y-%b-%d")
                }
            }
    
            response = post_lambda_client.invoke(
                FunctionName=BACKEND_FUNCTION_NAME,
                InvocationType='RequestResponse',
                Payload=json.dumps(payload)
            )
            
            print(f"lambda_response {response}")
            return redirect(url_for('get_all_posts'))

        except Exception as e:
            return jsonify({'error': str(e)})
    
# Route to delete a post
@app.route("/delete/<int:post_id>")
def delete_post(post_id):
    delete_lambda_client = boto3.client('lambda')
            
    payload = {
                "action": "delete",
                "item": {
                    "id":f"{post_id}"
                }
            }
    
    response = delete_lambda_client.invoke(
        FunctionName=BACKEND_FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
   
    return redirect(url_for('get_all_posts'))
    
# Route to edit a post
@app.route("/edit-post/<int:post_id>", methods=["GET", "POST"])
def edit_post(post_id):
    get_lambda_client = boto3.client('lambda')
    payload= { 
        "action": "get_one",
        "item": {
                "id":f"{post_id}"
            }
        }

    response = get_lambda_client.invoke(
        FunctionName=BACKEND_FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    post =  json.loads(response['Payload'].read().decode('utf-8'))
    post = json.loads(post.get("body"))
    
    if request.method == "GET":
        return render_template("make-post.html", post=post, is_edit=True, current_user=0, S3_ARN = S3_ARN)
    elif request.method == "POST":

        title = request.form.get('title')
        subtitle = request.form.get('subtitle')
        image_url = request.form.get('image_url')
        content = request.form.get('content')
    
        payload = payload = {
                "action": "update",
                "item": {
                    "id": f"{post_id}"
                },
                "update_expression": "SET title = :title, subtitle = :subtitle, image_url = :url, content = :content",
                "expression_values": {
                    ":title": title,
                    ":subtitle": subtitle,
                    ":url": f"{image_url}",
                    ":content": content
                }
            }

        response = get_lambda_client.invoke(
        FunctionName=BACKEND_FUNCTION_NAME,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
     
    return redirect(url_for("show_post", post_id=post_id))

# Route to get about information
@app.route("/about")
def about():
    return render_template("about.html", current_user=0,  S3_ARN = S3_ARN)

# Route to get an email
@app.route("/contact", methods=["GET","POST"])
def contact():
    if request.method == "POST":
        get_lambda_client = boto3.client('lambda')
        payload= { 
            "api_gw": API_GW,
            "user": {
                "email": request.form.get("email"),
                "name": request.form.get("name")
                }
            }
        
        response = get_lambda_client.invoke(
            FunctionName=EMAIL_FUNCTION_NAME,
            InvocationType='RequestResponse',
            Payload=json.dumps(payload)
        )
           
        return render_template("contact.html", msg_sent=True, S3_ARN = S3_ARN)
    return render_template("contact.html", msg_sent=False, S3_ARN = S3_ARN)



#Handler for lambda function
def handler(event, context):
    # Convert API Gateway event to Flask request
    path = event.get('rawPath')
    method = event.get('requestContext').get('http').get('method')
    headers = event.get("headers")
     
    if event.get('isBase64Encoded'):
        body = base64.b64decode(event.get('body'))
    else:
        body = event.get('body')

    print(f"body: {body}")
    print(f"event: {event}")

    #with app.app_context():
    with app.test_request_context(path=path, method=method, data=body, headers=headers):
        response = app.full_dispatch_request()
        return {
            'statusCode': response.status_code,
            'headers': dict(response.headers),
            'body': response.get_data(as_text=True)
        }
