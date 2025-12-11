#!/usr/bin/env python3
"""
Vulnerable Admin Panel for Advanced Kubernetes Security Lab
DO NOT USE IN PRODUCTION - Intentionally vulnerable!
"""

from flask import Flask, request, render_template_string, redirect, session, jsonify
import subprocess
import os
import functools

app = Flask(__name__)
app.secret_key = 'insecure-secret-key-12345'

# Default credentials - intentionally weak
USERS = {
    'admin': 'admin',
    'operator': 'operator123',
    'guest': 'guest'
}

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>ACME Admin Panel</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #1a1a2e;
            color: #eee;
        }
        .header {
            background: linear-gradient(135deg, #16213e 0%, #0f3460 100%);
            padding: 20px;
            text-align: center;
            border-bottom: 3px solid #e94560;
        }
        .container {
            max-width: 1000px;
            margin: 30px auto;
            padding: 20px;
        }
        .login-box {
            background: #16213e;
            padding: 40px;
            border-radius: 10px;
            max-width: 400px;
            margin: 100px auto;
            box-shadow: 0 0 20px rgba(233, 69, 96, 0.3);
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border: 1px solid #0f3460;
            border-radius: 5px;
            background: #1a1a2e;
            color: #eee;
            box-sizing: border-box;
        }
        button, .btn {
            background: #e94560;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 5px;
        }
        button:hover, .btn:hover {
            background: #ff6b6b;
        }
        .card {
            background: #16213e;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .nav {
            background: #0f3460;
            padding: 10px 20px;
        }
        .nav a {
            color: #eee;
            text-decoration: none;
            margin-right: 20px;
        }
        .nav a:hover { color: #e94560; }
        .output {
            background: #0a0a0a;
            color: #00ff00;
            padding: 15px;
            border-radius: 5px;
            font-family: monospace;
            white-space: pre-wrap;
            max-height: 400px;
            overflow-y: auto;
        }
        .error { color: #e94560; }
        .success { color: #00ff00; }
        .warning { 
            background: #ff9800;
            color: black;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #0f3460;
        }
        th { background: #0f3460; }
        .user-info {
            float: right;
            color: #aaa;
        }
    </style>
</head>
<body>
    <div class="header">
<<<<<<< Updated upstream
        <h1>ACME Corp Admin Panel</h1>
=======
        <h1>🔐 ACME Corp Admin Panel</h1>
>>>>>>> Stashed changes
        {% if session.get('user') %}
        <span class="user-info">Logged in as: {{ session.get('user') }} | <a href="/logout" style="color:#e94560;">Logout</a></span>
        {% endif %}
    </div>
    
    {% if not session.get('user') %}
    <div class="login-box">
        <h2>Login Required</h2>
        {% if error %}
        <p class="error">{{ error }}</p>
        {% endif %}
        <form method="POST" action="/login">
            <input type="text" name="username" placeholder="Username" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit" style="width:100%;">Login</button>
        </form>
        <p style="margin-top:20px;color:#666;font-size:12px;">Authorized personnel only</p>
    </div>
    {% else %}
    <div class="nav">
        <a href="/">Dashboard</a>
        <a href="/users">Users</a>
        <a href="/console">Debug Console</a>
        <a href="/config">Configuration</a>
        <a href="/backup">Backup</a>
    </div>
    <div class="container">
        {% if page == 'dashboard' %}
        <h2>Dashboard</h2>
        <div class="card">
            <h3>System Status</h3>
            <p>Hostname: {{ hostname }}</p>
            <p>Environment: {{ env }}</p>
            <p>Status: <span class="success">● Online</span></p>
        </div>
        <div class="card">
            <h3>Quick Actions</h3>
            <a href="/console" class="btn">Debug Console</a>
            <a href="/backup" class="btn">Run Backup</a>
            <a href="/config" class="btn">View Config</a>
        </div>
        
        {% elif page == 'users' %}
        <h2>User Management</h2>
        <div class="card">
            <table>
                <tr><th>Username</th><th>Role</th><th>Status</th></tr>
                <tr><td>admin</td><td>Administrator</td><td class="success">Active</td></tr>
                <tr><td>operator</td><td>Operator</td><td class="success">Active</td></tr>
                <tr><td>guest</td><td>Read-only</td><td class="success">Active</td></tr>
            </table>
        </div>
        
        {% elif page == 'console' %}
        <h2>Debug Console</h2>
<<<<<<< Updated upstream
        <div class="warning">Warning: This console executes commands on the server. Use with caution.</div>
=======
        <div class="warning">⚠️ Warning: This console executes commands on the server. Use with caution.</div>
>>>>>>> Stashed changes
        <div class="card">
            <form method="POST">
                <label>Enter command:</label>
                <input type="text" name="cmd" placeholder="e.g., ls -la" style="width:70%;">
                <button type="submit">Execute</button>
            </form>
            {% if output %}
            <h4>Output:</h4>
            <div class="output">{{ output }}</div>
            {% endif %}
        </div>
        
        {% elif page == 'config' %}
        <h2>Configuration</h2>
        <div class="card">
            <h3>Application Settings</h3>
            <pre class="output">{{ config }}</pre>
        </div>
        
        {% elif page == 'backup' %}
        <h2>Backup Management</h2>
        <div class="card">
            <h3>Database Backup</h3>
            <form method="POST">
                <label>Backup destination path:</label>
                <input type="text" name="path" placeholder="/backups/db-backup.sql" style="width:60%;">
                <button type="submit">Create Backup</button>
            </form>
            {% if output %}
            <div class="output">{{ output }}</div>
            {% endif %}
        </div>
        {% endif %}
    </div>
    {% endif %}
</body>
</html>
"""

def login_required(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user'):
            return redirect('/login')
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
@login_required
def dashboard():
    hostname = os.environ.get('HOSTNAME', 'unknown')
    env = os.environ.get('APP_ENV', 'production')
    return render_template_string(HTML_TEMPLATE, page='dashboard', hostname=hostname, env=env, session=session)

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username', '')
        password = request.form.get('password', '')
        if username in USERS and USERS[username] == password:
            session['user'] = username
            return redirect('/')
        error = 'Invalid credentials'
    return render_template_string(HTML_TEMPLATE, error=error, session=session)

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

@app.route('/users')
@login_required
def users():
    return render_template_string(HTML_TEMPLATE, page='users', session=session)

@app.route('/console', methods=['GET', 'POST'])
@login_required
def console():
    output = None
    if request.method == 'POST':
        cmd = request.form.get('cmd', '')
        if session.get('user') != 'admin':
            output = 'Error: Only admin can execute commands'
        else:
            try:
                # VULNERABLE: Direct command execution
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
                output = result.stdout + result.stderr
            except Exception as e:
                output = f'Error: {str(e)}'
    return render_template_string(HTML_TEMPLATE, page='console', output=output, session=session)

@app.route('/config')
@login_required
def config():
    # VULNERABLE: Exposes sensitive configuration
    config_data = f"""
Application: ACME Admin Panel
Version: 2.3.1
Environment: {os.environ.get('APP_ENV', 'production')}

Database Configuration:
  Host: {os.environ.get('DB_HOST', 'localhost')}
  User: {os.environ.get('DB_USER', 'root')}
  Password: {os.environ.get('DB_PASSWORD', 'not-set')}

API Keys:
  Internal API: {os.environ.get('INTERNAL_API_KEY', 'not-set')}
  
Service Account: {os.environ.get('HOSTNAME', 'unknown')}
"""
    return render_template_string(HTML_TEMPLATE, page='config', config=config_data, session=session)

@app.route('/backup', methods=['GET', 'POST'])
@login_required  
def backup():
    output = None
    if request.method == 'POST':
        path = request.form.get('path', '')
        # VULNERABLE: Path traversal and command injection
        try:
            output = f"Initiating backup to: {path}\n"
            result = subprocess.run(f'echo "Backup data" > {path}', shell=True, capture_output=True, text=True, timeout=10)
            output += result.stdout + result.stderr
            output += "\nBackup initiated (simulated)"
        except Exception as e:
            output = f'Error: {str(e)}'
    return render_template_string(HTML_TEMPLATE, page='backup', output=output, session=session)

@app.route('/health')
def health():
    return 'OK', 200

# VULNERABLE: Exposed debug endpoint
@app.route('/debug/env')
def debug_env():
    return jsonify(dict(os.environ))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)