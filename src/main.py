import functions_framework
import logging
from flask import abort
import sms_handler

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


@functions_framework.http
def root(request):
    logger.debug('Request received:')
    logger.debug(dict(request.headers))

    data = {}
    content_type = request.headers.get('Content-Type', '')
    if content_type == 'application/x-www-form-urlencoded':
        data = request.form
    elif content_type == 'application/json':
        data = request.get_json()

    logger.debug(f'payload received: {data}')

    if 'MessageSid' in data:
        logger.debug('Detected Twilio message')
        # handle incoming twilio message
        if not sms_handler.is_valid_twilio_request(request):
            return abort(403)

        response = sms_handler.handle_incoming_sms(data)
        return response

    return abort(400)
