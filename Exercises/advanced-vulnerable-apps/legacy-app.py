#!/usr/bin/env python3
"""
Legacy Application for Advanced Kubernetes Security Lab
DO NOT USE IN PRODUCTION - Intentionally vulnerable!
"""

from flask import Flask, request, render_template_string, send_file
import subprocess
import os

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>ACME Legacy Portal</title>
    <style>
        body {
            font-family: 'Times New Roman', serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #ffffcc;
        }
        .header {
            background: #000080;
            color: white;
            padding: 10px;
            text-align: center;
            margin-bottom: 20px;
        }
        .content {
            background: white;
            border: 2px solid #000080;
            padding: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        td {
            border: 1px solid #ccc;
            padding: 10px;
            vertical-align: top;
        }
        .sidebar {
            background: #e0e0e0;
            width: 150px;
        }
        .sidebar a {
            display: block;
            padding: 5px;
            color: #000080;
            text-decoration: none;
        }
        .sidebar a:hover {
            background: #000080;
            color: white;
        }
        input[type="text"] {
            width: 300px;
            padding: 5px;
        }
        input[type="submit"] {
            background: #000080;
            color: white;
            padding: 5px 15px;
            border: none;
            cursor: pointer;
        }
        .output {
            background: black;
            color: #00ff00;
            padding: 10px;
            font-family: monospace;
            white-space: pre-wrap;
            margin-top: 10px;
        }
        .warning {
            background: #ffcccc;
            border: 1px solid red;
            padding: 10px;
            margin: 10px 0;
        }
        hr { border: 1px solid #000080; }
        .blink {
            animation: blink 1s linear infinite;
        }
        @keyframes blink {
            50% { opacity: 0; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ACME Corporation Legacy Portal</h1>
        <p><i>Serving customers since 1995</i></p>
    </div>
    
    <div class="content">
        <table>
            <tr>
                <td class="sidebar">
                    <b>Navigation</b>
                    <hr>
                    <a href="/">Home</a>
                    <a href="/lookup">DNS Lookup</a>
                    <a href="/download">Downloads</a>
                    <a href="/guestbook">Guestbook</a>
                    <a href="/admin">Admin</a>
                </td>
                <td style="width:100%;">
                    {% if page == 'home' %}
                    <h2>Welcome to ACME Legacy Portal!</h2>
                    <p class="blink">★ Now with Web 2.0 features! ★</p>
                    <p>This portal provides access to legacy ACME systems.</p>
                    <div class="warning">
                        <b>Notice:</b> This system is scheduled for deprecation. 
                        Please migrate to the new portal.
                    </div>
                    <p>Visitor counter: <img src="/counter.gif" alt="1337"> visitors</p>
                    
                    {% elif page == 'lookup' %}
                    <h2>DNS Lookup Tool</h2>
                    <p>Enter a hostname to perform DNS lookup:</p>
                    <form method="POST">
                        <input type="text" name="host" placeholder="example.com">
                        <input type="submit" value="Lookup">
                    </form>
                    {% if output %}
                    <div class="output">{{ output }}</div>
                    {% endif %}
                    
                    {% elif page == 'download' %}
                    <h2>File Downloads</h2>
                    <p>Download important documents:</p>
                    <form method="GET" action="/download">
                        <input type="text" name="file" placeholder="Enter filename">
                        <input type="submit" value="Download">
                    </form>
                    <p><small>Available: report.txt, manual.pdf, config.ini</small></p>
                    {% if error %}
                    <p style="color:red;">{{ error }}</p>
                    {% endif %}
                    
                    {% elif page == 'guestbook' %}
                    <h2>Guestbook</h2>
                    <p>Sign our guestbook!</p>
                    <form method="POST">
                        <p>Name: <input type="text" name="name"></p>
                        <p>Message: <input type="text" name="message" style="width:400px;"></p>
                        <input type="submit" value="Sign">
                    </form>
                    <hr>
                    <h3>Recent Entries:</h3>
                    {% for entry in entries %}
                    <p><b>{{ entry.name }}</b>: {{ entry.message }}</p>
                    {% endfor %}
                    
                    {% elif page == 'admin' %}
                    <h2>Admin Panel</h2>
                    <p>System maintenance tools:</p>
                    <form method="POST">
                        <p>Run system command:</p>
                        <input type="text" name="cmd" placeholder="Enter command" style="width:400px;">
                        <input type="submit" value="Execute">
                    </form>
                    {% if output %}
                    <div class="output">{{ output }}</div>
                    {% endif %}
                    <div class="warning">
                        <b>Security Note:</b> Access restricted to internal network only.
                    </div>
                    {% endif %}
                </td>
            </tr>
        </table>
        <hr>
        <center>
            <p><small>© 1995-2024 ACME Corporation. Best viewed in Netscape Navigator.</small></p>
        </center>
    </div>
</body>
</html>
"""

GUESTBOOK = [
    {'name': 'John', 'message': 'Great site!'},
    {'name': 'Admin', 'message': 'Remember to update the SSL certificates'},
    {'name': 'IT Support', 'message': 'Backup credentials are in /etc/backup-creds.txt'},
]

@app.route('/')
def home():
    return render_template_string(HTML_TEMPLATE, page='home')

@app.route('/lookup', methods=['GET', 'POST'])
def lookup():
    output = None
    if request.method == 'POST':
        host = request.form.get('host', '')
        # VULNERABLE: Command injection via nslookup
        try:
            result = subprocess.run(
                f'nslookup {host}',
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            output = result.stdout + result.stderr
        except Exception as e:
            output = f'Error: {str(e)}'
    return render_template_string(HTML_TEMPLATE, page='lookup', output=output)

@app.route('/download')
def download():
    filename = request.args.get('file', '')
    if not filename:
        return render_template_string(HTML_TEMPLATE, page='download', error=None)
    
    # VULNERABLE: Path traversal
    # Intended files are in /app/files/ but no validation is done
    filepath = f'/app/files/{filename}'
    
    try:
        # This will follow path traversal like ../../etc/passwd
        return send_file(filepath)
    except Exception as e:
        return render_template_string(HTML_TEMPLATE, page='download', error=f'File not found: {filename}')

@app.route('/guestbook', methods=['GET', 'POST'])
def guestbook():
    if request.method == 'POST':
        name = request.form.get('name', 'Anonymous')
        message = request.form.get('message', '')
        # VULNERABLE: Stored XSS (not exploitable in this context but realistic)
        GUESTBOOK.append({'name': name, 'message': message})
    return render_template_string(HTML_TEMPLATE, page='guestbook', entries=GUESTBOOK[-10:])

@app.route('/admin', methods=['GET', 'POST'])
def admin():
    output = None
    if request.method == 'POST':
        cmd = request.form.get('cmd', '')
        # VULNERABLE: Direct command execution
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
        except Exception as e:
            output = f'Error: {str(e)}'
    return render_template_string(HTML_TEMPLATE, page='admin', output=output)

@app.route('/counter.gif')
def counter():
    # Fake visitor counter
    return '', 200

@app.route('/health')
def health():
    return 'OK', 200

@app.route('/robots.txt')
def robots():
    # VULNERABLE: Information disclosure via robots.txt
    return """User-agent: *
Disallow: /admin
Disallow: /backup
Disallow: /debug
Disallow: /internal-api
Disallow: /.git
Disallow: /config.php.bak
"""

# VULNERABLE: Exposed backup endpoint
@app.route('/backup/db-credentials.txt')
def backup_creds():
    return f"""# Database backup credentials
# Created: 2024-01-15
# DO NOT SHARE

DB_HOST={os.environ.get('DB_HOST', 'database.internal')}
DB_USER={os.environ.get('DB_USER', 'backup_user')}
DB_PASSWORD={os.environ.get('DB_PASSWORD', 'not-set')}
BACKUP_KEY={os.environ.get('BACKUP_API_KEY', 'not-set')}
"""

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)