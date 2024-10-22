import functions_framework
import os
from flask import abort
from twilio.rest import Client
from twilio.request_validator import RequestValidator
from twilio.twiml.messaging_response import Message, MessagingResponse
from pprint import pprint

TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN','')
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID','')
TWILIO_OUTBOUND_NUMBER = os.getenv('TWILIO_OUTBOUND_NUMBER','')
TESTING_NUMBER = os.getenv('TESTING_NUMBER','')

@functions_framework.http
def root(request):
    # only accept JSON requests, either from Twilio or from
    # cloud scheduler
    print('Request received:')
    print(dict(request.headers))
    print(dict(request.form))

    data = request.get_json() or request.form
    if 'MessageSid' in data:
        # handle incoming twilio message
        if not is_valid_twilio_request(request):
            return abort(403)

        print('SMS recieved:')
        print(data['Body'])
        response = MessagingResponse()
        response.message(f"Message received: {data['body']}")
        return response
    
    return abort(400)


def is_valid_twilio_request(request):
    validator = RequestValidator(TWILIO_AUTH_TOKEN)
    print('validating twilio request')
    print(request.url)
    print(request.form)
    print(request.headers.get('X-TWILIO-SIGNATURE',''))
    return validator.validate(
        request.url, request.form, request.headers.get('X-TWILIO-SIGNATURE', ''))

# Routes:
#  /cron - schedules daily notifications
#        - verify oidc token
#  /twiml - receives twilio webhooks
#         - verify twilio