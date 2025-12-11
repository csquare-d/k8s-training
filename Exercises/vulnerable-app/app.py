#!/usr/bin/env python3
"""
Vulnerable Web Application for Kubernetes Security Lab
DO NOT USE IN PRODUCTION - Intentionally vulnerable!
"""

from flask import Flask, request, render_template_string
import subprocess
import os

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>ACME Corp Internal Tools</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .warning {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        input[type="text"] {
            width: 300px;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        button:hover { background-color: #0056b3; }
        .output {
            background-color: #1e1e1e;
            color: #00ff00;
            padding: 15px;
            border-radius: 4px;
            font-family: monospace;
            white-space: pre-wrap;
            margin-top: 20px;
            max-height: 400px;
            overflow-y: auto;
        }
        .nav {
            margin-bottom: 20px;
        }
        .nav a {
            margin-right: 15px;
            color: #007bff;
            text-decoration: none;
        }
        .nav a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>ACME Corp Internal Tools</h1>
        <div class="nav">
            <a href="/">Home</a>
            <a href="/diagnostics">Network Diagnostics</a>
            <a href="/status">System Status</a>
        </div>
        {% if page == 'home' %}
            <h2>Welcome!</h2>
            <p>Internal tools for ACME Corp employees.</p>
            <p>Please use the navigation above to access available tools.</p>
            <div class="warning">
            This system is for authorized personnel only. All access is logged.
            </div>
        {% elif page == 'diagnostics' %}
            <h2>Network Diagnostics</h2>
            <p>Use this tool to check connectivity to internal and external hosts.</p>
            <form method="POST">
                <label for="host">Enter hostname or IP to ping:</label><br>
                <input type="text" id="host" name="host" placeholder="e.g., 8.8.8.8" required>
                <button type="submit">Run Diagnostic</button>
            </form>
            {% if output %}
            <div class="output">{{ output }}</div>
            {% endif %}
        {% elif page == 'status' %}
            <h2>System Status</h2>
            <p><strong>Hostname:</strong> {{ hostname }}</p>
            <p><strong>Platform:</strong> {{ platform }}</p>
            <p><strong>Status:</strong> <span style="color: green;">● Online</span></p>
        {% endif %}
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    return render_template_string(HTML_TEMPLATE, page='home')

@app.route('/diagnostics', methods=['GET', 'POST'])
def diagnostics():
    output = None
    if request.method == 'POST':
        host = request.form.get('host', '')
        # VULNERABLE: Command injection - user input passed directly to shell
        # This is intentionally vulnerable for the security lab
        try:
            result = subprocess.run(
                f'ping -c 2 {host}',
                shell=True,  # Vulnerable!
                capture_output=True,
                text=True,
                timeout=10
            )
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            output = "Command timed out"
        except Exception as e:
            output = f"Error: {str(e)}"
    
    return render_template_string(HTML_TEMPLATE, page='diagnostics', output=output)

@app.route('/status')
def status():
    hostname = os.environ.get('HOSTNAME', 'unknown')
    platform = "Kubernetes Pod"
    return render_template_string(HTML_TEMPLATE, page='status', hostname=hostname, platform=platform)

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)