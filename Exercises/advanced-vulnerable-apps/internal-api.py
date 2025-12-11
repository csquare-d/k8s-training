#!/usr/bin/env python3
"""
Vulnerable Internal API for Advanced Kubernetes Security Lab
DO NOT USE IN PRODUCTION - Intentionally vulnerable!
"""

from flask import Flask, request, jsonify, render_template_string
import requests
import os
import subprocess

app = Flask(__name__)

HTML_DOCS = """
<!DOCTYPE html>
<html>
<head>
    <title>ACME Internal API</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background: #f8f9fa;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        code {
            background: #ecf0f1;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
        }
        pre {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .endpoint {
            background: #e8f4f8;
            padding: 15px;
            border-left: 4px solid #3498db;
            margin: 15px 0;
        }
        .method {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-weight: bold;
            margin-right: 10px;
        }
        .get { background: #27ae60; color: white; }
        .post { background: #e67e22; color: white; }
        .try-it {
            background: #3498db;
            color: white;
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 10px;
        }
        .try-it:hover { background: #2980b9; }
        input[type="text"] {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .response {
            background: #1e1e1e;
            color: #00ff00;
            padding: 15px;
            border-radius: 5px;
            font-family: monospace;
            white-space: pre-wrap;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>ACME Internal API Documentation</h1>
        <p>Welcome to the ACME Internal API. This API provides internal services for ACME Corp applications.</p>
        
        <h2>Available Endpoints</h2>
        
        <div class="endpoint">
            <span class="method get">GET</span> <code>/api/health</code>
            <p>Health check endpoint</p>
        </div>
        
        <div class="endpoint">
            <span class="method get">GET</span> <code>/api/info</code>
            <p>Returns service information</p>
        </div>
        
        <div class="endpoint">
            <span class="method post">POST</span> <code>/api/fetch</code>
            <p>Fetch content from internal URLs (for service-to-service communication)</p>
            <p><strong>Parameters:</strong></p>
            <ul>
                <li><code>url</code> - The URL to fetch</li>
            </ul>
            <form id="fetchForm" onsubmit="return testFetch()">
                <input type="text" id="fetchUrl" name="url" placeholder="Enter URL to fetch (e.g., http://example.com)">
                <button type="submit" class="try-it">Try It</button>
            </form>
            <div id="fetchResponse" class="response" style="display:none;"></div>
        </div>
        
        <div class="endpoint">
            <span class="method get">GET</span> <code>/api/webhook/test</code>
            <p>Test webhook connectivity</p>
            <p><strong>Parameters:</strong></p>
            <ul>
                <li><code>callback</code> - Callback URL to test</li>
            </ul>
        </div>
        
        <div class="endpoint">
            <span class="method get">GET</span> <code>/metrics</code>
            <p>Prometheus metrics endpoint</p>
        </div>
        
        <h2>Authentication</h2>
        <p>Internal API uses service account authentication. Requests from within the cluster are automatically authenticated.</p>
        
        <h2>Notes</h2>
        <p>This API is for internal use only. External access should be restricted.</p>
    </div>
    
    <script>
        async function testFetch() {
            const url = document.getElementById('fetchUrl').value;
            const responseDiv = document.getElementById('fetchResponse');
            try {
                const response = await fetch('/api/fetch', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({url: url})
                });
                const data = await response.json();
                responseDiv.textContent = JSON.stringify(data, null, 2);
                responseDiv.style.display = 'block';
            } catch (e) {
                responseDiv.textContent = 'Error: ' + e.message;
                responseDiv.style.display = 'block';
            }
            return false;
        }
    </script>
</body>
</html>
"""

@app.route('/')
def docs():
    return render_template_string(HTML_DOCS)

@app.route('/api/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'internal-api'})

@app.route('/api/info')
def info():
    return jsonify({
        'service': 'ACME Internal API',
        'version': '1.4.2',
        'hostname': os.environ.get('HOSTNAME', 'unknown'),
        'environment': os.environ.get('APP_ENV', 'production')
    })

@app.route('/api/fetch', methods=['POST'])
def fetch_url():
    """
    VULNERABLE: Server-Side Request Forgery (SSRF)
    Allows fetching arbitrary URLs including internal services
    """
    data = request.get_json() or {}
    url = data.get('url') or request.args.get('url', '')
    
    if not url:
        return jsonify({'error': 'URL parameter required'}), 400
    
    try:
        # VULNERABLE: No URL validation, allows access to internal services
        response = requests.get(url, timeout=5)
        return jsonify({
            'url': url,
            'status_code': response.status_code,
            'content': response.text[:5000],  # Limit response size
            'headers': dict(response.headers)
        })
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/webhook/test')
def webhook_test():
    """
    VULNERABLE: Another SSRF vector via callback parameter
    """
    callback = request.args.get('callback', '')
    if not callback:
        return jsonify({'error': 'callback parameter required'}), 400
    
    try:
        response = requests.get(callback, timeout=5)
        return jsonify({
            'callback': callback,
            'status': 'reached',
            'response_code': response.status_code
        })
    except Exception as e:
        return jsonify({'callback': callback, 'status': 'failed', 'error': str(e)})

@app.route('/metrics')
def metrics():
    """Prometheus-style metrics endpoint"""
    metrics_data = """# HELP api_requests_total Total API requests
# TYPE api_requests_total counter
api_requests_total{endpoint="/api/fetch"} 1523
api_requests_total{endpoint="/api/health"} 8234

# HELP api_errors_total Total API errors  
# TYPE api_errors_total counter
api_errors_total{endpoint="/api/fetch"} 12

# HELP service_info Service information
# TYPE service_info gauge
service_info{version="1.4.2",hostname="%s"} 1
""" % os.environ.get('HOSTNAME', 'unknown')
    return metrics_data, 200, {'Content-Type': 'text/plain'}

# VULNERABLE: Debug endpoint that shouldn't exist in production
@app.route('/debug/config')
def debug_config():
    return jsonify({
        'database': {
            'host': os.environ.get('DB_HOST', 'not-set'),
            'user': os.environ.get('DB_USER', 'not-set'),
            'password': os.environ.get('DB_PASSWORD', 'not-set')
        },
        'api_keys': {
            'internal': os.environ.get('INTERNAL_API_KEY', 'not-set')
        },
        'kubernetes': {
            'namespace': os.environ.get('POD_NAMESPACE', 'not-set'),
            'pod_name': os.environ.get('HOSTNAME', 'not-set'),
            'service_account': 'internal-api-sa'
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)