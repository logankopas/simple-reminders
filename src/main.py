import functions_framework
import os
from twilio.rest import Client

TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN','')
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID','')
TWILIO_OUTBOUND_NUMBER = os.getenv('TWILIO_OUTBOUND_NUMBER','')
TESTING_NUMBER = os.getenv('TESTING_NUMBER','')

print(TWILIO_ACCOUNT_SID)

@functions_framework.http
def root(request):
    content_type = request.headers["Content-Type"]
    if content_type != 'application/json':
        raise RuntimeError()
    data = request.get_json()
    if 'MessageSid' in data:
        # handle incoming message
        print('SMS recieved:')
        print(data['body'])
    else:
        # send test message
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            from_=TWILIO_OUTBOUND_NUMBER,
            to=TESTING_NUMBER,
            body="This is a test message"
        )
        print(message.sid)
        return "success", 200





# Routes:
#  /cron - schedules daily notifications
#        - verify oidc token
#  /twiml - receives twilio webhooks
#         - verify twilio