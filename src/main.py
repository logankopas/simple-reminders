import functions_framework

@functions_framework.http
def root(request):
    return 'hello'
