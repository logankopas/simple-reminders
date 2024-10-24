from flask import Response
from twilio.rest import Client
from twilio.request_validator import RequestValidator
from twilio.twiml.messaging_response import Message, MessagingResponse
from urllib.parse import urlparse, urljoin
import logging

from settings import (
    TWILIO_AUTH_TOKEN, 
    TWILIO_ACCOUNT_SID, 
    TWILIO_OUTBOUND_NUMBER,
    TESTING_NUMBER,
    FN_NAME
) 

logger = logging.getLogger()


def is_valid_twilio_request(request):
    validator = RequestValidator(TWILIO_AUTH_TOKEN)
    url = request.url
    if request.headers.get('X-Forwarded-Proto','') == 'https':
        # If SSL termination already happened, update the request url
        # to match the original request
        url = url.replace('http://', 'https://')
    if urlparse(url).path in ('', '/'):
        # GCF strips the service name from the request, so add that back
        url = urljoin(url, FN_NAME)
    
    logger.debug(f'Validating twilio request for {url}')
    is_valid = validator.validate(
        url, request.form, request.headers.get('X-TWILIO-SIGNATURE', ''))
    if is_valid:
        logger.debug('Twilio response validated')
    else:
        logger.debug('Invalid twilio response received')
    return is_valid

def handle_incoming_sms(data):
    message_content = data['Body']
    logger.debug('SMS recieved:')
    logger.debug(data['Body'])

    # TODO next: dispatch based on keywords
    response = MessagingResponse()
    response.message(f"Message received: \n{data['Body']}")
    return Response(str(response), mimetype='application/xml')


def detect_keywords(message):
    kw_to_fn_map = {
        'list': list_scheduled_messages,
        'delete': delete_scheduled_message,
        'remind': new_reminder_message
    }

def list_scheduled_messages(*args, **kwargs):
    pass

def delete_scheduled_message(*args, **kwargs):
    pass

def new_reminder_message(*args, **kwargs):
    pass