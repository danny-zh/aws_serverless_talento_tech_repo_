import boto3, os, json

SOURCE = os.environ.get("email_source")

html_body = """
        <html>
        <head></head>
        <body>
            <h1>Hello!</h1>
            <p>¡{name}, gracias por contactarnos!. 
                Uno de nuestro asesores se pondrá en contacto
                contigo pronto \n. Más información en nuestro sitio web
                <a href="{url}">birdsbogota.com</a>
            </p>
        </body>
        </html>
    """
charset = "UTF-8"

def handler(event, context):
        client = boto3.client('ses', region_name='us-east-1')
        
        user = event.get("user")
        
        SUBJECT = "Hemos recibido tu correo"
        BODY = html_body.format(name=user.get('name').title(), url=event.get('api_gw') )
    
        try:
            response = client.send_email(
                Source=SOURCE,
                Destination={
                    'ToAddresses': [user.get("email")],
                },
                Message={
                    'Subject': {
                        'Data': SUBJECT,
                        'Charset': charset
                    },
                    'Body': {
                        'Html': {
                            'Data': BODY,
                            'Charset': charset
                        }
                    }
                }
            )
            return response

        except Exception as e:
           return {
            'statusCode': 500,
            'body': json.dumps(f'Failed to insert data: {e.response["Error"]["Message"]}')
        }

