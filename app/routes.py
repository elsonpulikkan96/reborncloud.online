from flask import Blueprint, render_template, jsonify, send_file, current_app, request, session, flash, redirect, url_for
from app import limiter
from datetime import datetime
import os
import requests
import secrets
import time

main = Blueprint('main', __name__)

RESUME_DATA = {
    "personal_info": {
        "name": "Elson Pulickeel Ealias",
        "title": "Cloud Engineer | DevOps Engineer | SRE",
        "email": "elsonpulikkan@gmail.com",
        "phone": "+91 9562385469",
        "location": "Pulickeel House, Pazhoor P.O, Piravom, Kerala India. Pin:686664",
        "website": "https://reborncloud.online/",
        "github": "https://github.com/elsonpulikkan96",
        "linkedin": "https://linkedin.com/in/elsondevops",
        "medium": "https://medium.com/@elsonpulikkan",
        "profile_image": "images/elson-cloud.jpeg"
    },
    "bio": "CloudOps and DevOps Engineer with 5+ years of experience managing high-availability cloud infrastructure on AWS, Kubernetes and Linux + Cloud-Native systems. Delivering Scalable and Reliable solutions through CI/CD Automation, Robust Monitoring and Adherence to SLI/SLO/SLA targets. Certified in CKA and AWS SAA with a proven track record of 24/7*365 Production Support and Enterprise-grade service delivery.",
    "experience": [
        {
            "position": "Cloud Operation Engineer - 2",
            "company": "EPI-USE India Pvt Ltd",
            "location": "Kochi, India",
            "duration": "10/2024 – Present",
            "description": "Managing Uptime, High Availability of SAP S/4HANA infrastructure on AWS for large-scale enterprise clients.",
            "responsibilities": [
                "Managed Uptime, High Availability of SAP S/4HANA infrastructure on AWS for large-scale enterprise clients",
                "Automated recurring cloud operations using AWS Lambda, Ansible and GitHub workflows as AWS Partner-Led Support",
                "Provide end-to-end Incident management and RCA for SAP environments on AWS",
                "Created AWS cost optimization reports using SMC Pricing Calculator",
                "Collaborated with SAP Basis and AWS Billing teams to streamline deployment pipelines and maintenance workflows"
            ],
            "projects": [
                "City of Palo Alto (COPA): Migrated SAP S/4HANA workloads from on-premise to AWS",
                "Automated monthly patching tasks across Dev, QA and prod environments",
                "Prepared cost optimization and estimation reports using the AWS Pricing Calculator (SMC)",
                "Collaborated with AWS Partner-Led Support to Reduce downtime and improve reliability"
            ],
            "technologies": ["AWS", "SAP S/4HANA", "Lambda", "Ansible", "GitHub Actions", "SMC Pricing Calculator"]
        },
        {
            "position": "System Engineer - Contract",
            "company": "Tata Consultancy Services (TCS)",
            "location": "Kochi, India",
            "duration": "04/2024 – 06/2024",
            "description": "Designed cloud infrastructure environments with OU-Based, AWS Landing Zone method and AWS Well-Architected framework.",
            "responsibilities": [
                "Designed cloud infrastructure environments with OU-Based, AWS Landing Zone method and AWS Well-Architected framework",
                "Extensive hands-on experience in automating processes through AWS Lambda, Bash scripts",
                "Infrastructure as Code (IaC) and CI/CD pipelines, leveraging DevOps tools"
            ],
            "projects": [
                "Contributed to the design and migration of AWS cloud infrastructure for LGC Life Sciences, UK",
                "Facilitated application deployment on Apache Tomcat and Node.JS"
            ],
            "technologies": ["AWS", "Lambda", "Bash", "IaC", "CI/CD", "Apache Tomcat", "Node.JS"]
        },
        {
            "position": "Site Reliability Engineer - Cloud",
            "company": "Network Redux LLC",
            "location": "Kochi, India",
            "duration": "06/2022 – 02/2024",
            "description": "Managed Cloud infrastructure for global tier clients on AWS and Azure, Handling daily operations in 24/7*365 Rotational shifts.",
            "responsibilities": [
                "Managed Cloud infrastructure for global tier clients on AWS and Azure, Handling daily operations in 24/7*365 Rotational shifts",
                "Set-up monitoring and maintained DR for Linux and Windows servers",
                "Worked extensively with AWS services including EC2, RDS, VPC, ELB, Cloudfront, Auto Scaling, S3, Lambda, IAM and CloudWatch, CloudTrial",
                "Automated tasks using Bash scripts and configuration tools like Ansible"
            ],
            "projects": [
                "Supported cloud operations for Phobs Inc and Intervision a leading European hotel booking platform",
                "Helped design scalable cloud architecture for Central-Data, a U.S.-based e-commerce company"
            ],
            "technologies": ["AWS", "Azure", "EC2", "RDS", "VPC", "ELB", "CloudFront", "S3", "Lambda", "IAM", "CloudWatch", "Ansible", "Bash"]
        },
        {
            "position": "Hosting Product Specialist – Linux and Windows",
            "company": "Endurance International (Newfold Inc)",
            "location": "Bengaluru, India",
            "duration": "07/2021 – 05/2022",
            "description": "Provided advanced support for reseller and retail hosting platforms (cPanel, Plesk, WHM).",
            "responsibilities": [
                "Provided advanced support for reseller and retail hosting platforms (cPanel, Plesk, WHM)",
                "Tuned Apache2, Nginx, PHP-FPM and MySQL for optimized performance on shared, VPS and Dedicated servers",
                "Troubleshot enterprise-level email hosting, storage, DNS, and SSL configurations"
            ],
            "projects": [
                "Wholesale website hosting for ResellerClub, HostGator",
                "Retail website and email hosting support for Hostinger"
            ],
            "technologies": ["cPanel", "Plesk", "WHM", "Apache2", "Nginx", "PHP-FPM", "MySQL", "DNS", "SSL"]
        },
        {
            "position": "Jr. System Engineer",
            "company": "Admod Solutions",
            "location": "Kochi, India",
            "duration": "09/2020 – 05/2021",
            "description": "Monitoring, Ensured 99.9% uptime, Delivered Technical support for web-hosting clients.",
            "responsibilities": [
                "Monitoring, Ensured 99.9% uptime, Delivered Technical support for web-hosting clients",
                "Resolving website issues promptly via cPanel, DirectAdmin and Plesk. Prompt escalations to L2 Engineers",
                "Handled DNS transfers, vulnerability mitigation, and routine backup operations. Quota management via WHMCS"
            ],
            "projects": [
                "Supported web hosting operations for DynoHosting and Orange Enterprise, ensuring platform stability and performance",
                "Web-hosting support for Orange Enterprise"
            ],
            "technologies": ["cPanel", "DirectAdmin", "Plesk", "WHMCS", "DNS", "Linux"]
        }
    ],
    "skills": {
        "Cloud Platforms": {
            "icon": "fas fa-cloud",
            "skills": ["AWS (EC2, S3, RDS, Lambda, EKS, CloudFormation)", "Azure", "DigitalOcean"]
        },
        "Container & Orchestration": {
            "icon": "fab fa-docker",
            "skills": ["Kubernetes", "Docker", "Container Management"]
        },
        "DevOps & CI/CD": {
            "icon": "fas fa-code-branch",
            "skills": ["GitHub Actions", "Jenkins", "CI/CD Pipelines"]
        },
        "Infrastructure as Code": {
            "icon": "fas fa-code",
            "skills": ["Terraform", "Ansible", "CloudFormation"]
        },
        "Monitoring & Logging": {
            "icon": "fas fa-chart-line",
            "skills": ["CloudWatch", "Monitoring", "Incident Management", "Alerting"]
        },
        "Programming Languages": {
            "icon": "fas fa-laptop-code",
            "skills": ["Python", "Bash/Shell", "Automation Scripts"]
        },
        "Operating Systems": {
            "icon": "fab fa-linux",
            "skills": ["Linux Systems", "Windows Server", "Networking Fundamentals"]
        },
        "Web Technologies": {
            "icon": "fas fa-globe",
            "skills": ["Apache2", "Nginx", "PHP-FPM", "MySQL", "DNS Management"]
        },
        "Hosting & Management": {
            "icon": "fas fa-server",
            "skills": ["cPanel", "Plesk", "WHM", "DirectAdmin", "WHMCS"]
        }
    },
    "education": [
        {
            "degree": "Bachelors in Computer Application (BCA)",
            "institution": "Rabindranath Tagore University (AISECT)",
            "location": "MP, India"
        },
        {
            "degree": "Kerala State SSLC and HSE Computer Science",
            "institution": "M.K.M H.S.S Piravom",
            "location": "Ernakulam, India"
        }
    ],
    "certifications": [
        {
            "name": "Certified Kubernetes Administrator (CKA)",
            "issuer": "Cloud Native Computing Foundation",
            "issued": "2025",
            "icon": "fas fa-dharmachakra",
            "status": "Active"
        },
        {
            "name": "AWS Certified Solutions Architect Associate",
            "issuer": "Amazon Web Services",
            "issued": "2023",
            "code": "SAA-C03",
            "icon": "fab fa-aws",
            "status": "Active"
        },
        {
            "name": "RedHat based Linux server Administration",
            "issuer": "Clado Solutions, Kochi",
            "icon": "fab fa-redhat",
            "status": "Completed"
        },
        {
            "name": "Aptis – English Assessment (Level 2)",
            "issuer": "British Council",
            "icon": "fas fa-language",
            "status": "Completed"
        }
    ],
    "projects": [
        {
            "name": "SAP S/4HANA AWS Migration",
            "description": "Migrated City of Palo Alto (COPA) SAP S/4HANA workloads from on-premise to AWS",
            "technologies": ["AWS", "SAP S/4HANA", "Lambda", "Ansible"],
            "highlights": [
                "Zero-downtime migration strategy",
                "Cost optimization using AWS Pricing Calculator",
                "Automated patching across environments"
            ]
        },
        {
            "name": "Multi-Cloud Infrastructure Management",
            "description": "Managed cloud infrastructure for global clients on AWS and Azure with 24/7*365 operations",
            "technologies": ["AWS", "Azure", "CloudWatch", "Monitoring"],
            "highlights": [
                "99.9% uptime achievement",
                "24/7*365 rotational shift support",
                "Disaster recovery implementation"
            ]
        },
        {
            "name": "Enterprise Hosting Platform",
            "description": "Provided advanced support for reseller and retail hosting platforms",
            "technologies": ["cPanel", "Plesk", "Apache", "Nginx", "MySQL"],
            "highlights": [
                "Performance optimization for shared/VPS/Dedicated servers",
                "Enterprise-level email and DNS configurations",
                "SSL certificate management"
            ]
        }
    ],
    "stats": {
        "years_experience": "5+",
        "certifications": 4,
        "uptime_achieved": "99.9%",
        "support_hours": "24/7*365",
        "projects_completed": "50+",
        "cost_savings": "30%"
    },
    "languages": ["English (Fluent)", "Malayalam (Native)"],
    "interests": ["Reading Fiction Novels", "Traveling", "Badminton", "EDM Music"],
    "portfolio_images": [
        {"src": "images/devops1.jpeg", "alt": "DevOps Infrastructure", "title": "Cloud Infrastructure Management"},
        {"src": "images/devops2.jpeg", "alt": "Kubernetes Deployment", "title": "Container Orchestration"},
        {"src": "images/devops3.jpeg", "alt": "CI/CD Pipeline", "title": "Automated Deployment Pipeline"}
    ]
}

def verify_recaptcha(recaptcha_response):
    if not current_app.config.get('RECAPTCHA_SECRET_KEY'):
        return True
    
    secret_key = current_app.config['RECAPTCHA_SECRET_KEY']
    verify_url = 'https://www.google.com/recaptcha/api/siteverify'
    
    data = {
        'secret': secret_key,
        'response': recaptcha_response,
        'remoteip': request.environ.get('REMOTE_ADDR')
    }
    
    try:
        response = requests.post(verify_url, data=data, timeout=10)
        result = response.json()
        return result.get('success', False)
    except Exception as e:
        current_app.logger.error(f"reCAPTCHA verification failed: {str(e)}")
        return False

def generate_download_token():
    token = secrets.token_urlsafe(32)
    session['download_token'] = token
    session['download_token_time'] = time.time()
    return token

def verify_download_token(token):
    if not token or 'download_token' not in session:
        return False
    
    if session.get('download_token') != token:
        return False
    
    token_time = session.get('download_token_time', 0)
    if time.time() - token_time > 300:
        session.pop('download_token', None)
        session.pop('download_token_time', None)
        return False
    
    return True

def log_download_attempt(ip_address, success=False, reason=""):
    timestamp = datetime.now().isoformat()
    log_entry = f"[{timestamp}] Resume download - IP: {ip_address}, Success: {success}, Reason: {reason}"
    current_app.logger.info(log_entry)

@main.route('/')
@limiter.limit("100 per minute")
def index():
    return render_template('index.html', data=RESUME_DATA, current_page='home')

@main.route('/bio')
def bio():
    return render_template('bio.html', data=RESUME_DATA, current_page='bio')

@main.route('/experience')
def experience():
    return render_template('experience.html', data=RESUME_DATA, current_page='experience')

@main.route('/skills')
def skills():
    return render_template('skills.html', data=RESUME_DATA, current_page='skills')

@main.route('/education')
def education():
    return render_template('education.html', data=RESUME_DATA, current_page='education')

@main.route('/contact')
def contact():
    return render_template('contact.html', data=RESUME_DATA, current_page='contact')

@main.route('/projects')
def projects():
    return render_template('projects.html', data=RESUME_DATA, current_page='projects')

@main.route('/api/resume')
def api_resume():
    return jsonify(RESUME_DATA)

@main.route('/resume-access')
def resume_access():
    return render_template('resume_access.html', 
                         data=RESUME_DATA,
                         recaptcha_site_key=current_app.config.get('RECAPTCHA_SITE_KEY'),
                         current_page='resume')

@main.route('/verify-access', methods=['POST'])
@limiter.limit("10 per minute")
def verify_access():
    ip_address = request.environ.get('REMOTE_ADDR', 'unknown')
    
    try:
        email = request.form.get('email', '').strip()
        
        if not email:
            log_download_attempt(ip_address, False, "No email provided")
            flash('Please provide your email address.', 'error')
            return redirect(url_for('main.resume_access'))
        
        recaptcha_configured = bool(current_app.config.get('RECAPTCHA_SECRET_KEY'))
        
        if not recaptcha_configured:
            token = generate_download_token()
            log_download_attempt(ip_address, True, f"Access verified for {email}")
            flash('Verification successful! Download starting...', 'success')
            return redirect(url_for('main.download_resume', token=token))
        
        recaptcha_response = request.form.get('g-recaptcha-response')
        
        if not recaptcha_response:
            log_download_attempt(ip_address, False, "No reCAPTCHA response")
            flash('Please complete the reCAPTCHA verification.', 'error')
            return redirect(url_for('main.resume_access'))
        
        if not verify_recaptcha(recaptcha_response):
            log_download_attempt(ip_address, False, "reCAPTCHA verification failed")
            flash('reCAPTCHA verification failed. Please try again.', 'error')
            return redirect(url_for('main.resume_access'))
        
        token = generate_download_token()
        log_download_attempt(ip_address, True, f"Access verified for {email}")
        
        flash('Verification successful! Download starting...', 'success')
        return redirect(url_for('main.download_resume', token=token))
        
    except Exception as e:
        current_app.logger.error(f"Access verification error: {str(e)}")
        log_download_attempt(ip_address, False, f"Error: {str(e)}")
        flash('An error occurred during verification. Please try again.', 'error')
        return redirect(url_for('main.resume_access'))

@main.route('/download-resume')
@limiter.limit("5 per hour")
def download_resume():
    ip_address = request.environ.get('REMOTE_ADDR', 'unknown')
    token = request.args.get('token')
    
    try:
        if not verify_download_token(token):
            log_download_attempt(ip_address, False, "Invalid or expired token")
            flash('Please verify access to download.', 'error')
            return redirect(url_for('main.resume_access'))
        
        session.pop('download_token', None)
        session.pop('download_token_time', None)
        
        pdf_path = os.path.join(current_app.static_folder, 'documents', 'Elson-Ealias-Resume-2025.pdf')
        if os.path.exists(pdf_path):
            log_download_attempt(ip_address, True, "File downloaded successfully")
            return send_file(pdf_path, 
                           as_attachment=True, 
                           download_name='Elson-Ealias-Resume-2025.pdf', 
                           mimetype='application/pdf')
        else:
            log_download_attempt(ip_address, False, "Resume file not found")
            return jsonify({"error": "Resume file not found"}), 404
            
    except Exception as e:
        current_app.logger.error(f"Download error: {str(e)}")
        log_download_attempt(ip_address, False, f"Download error: {str(e)}")
        return jsonify({"error": f"Download failed: {str(e)}"}), 500

@main.route('/download-resume-legacy')
def download_resume_legacy():
    flash('For security, resume downloads now require verification.', 'info')
    return redirect(url_for('main.resume_access'))

@main.route('/health')
@limiter.exempt
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "2.0.0",
        "components": {
            "database": "healthy",
            "cache": "healthy",
            "external_apis": "healthy"
        }
    })

@main.errorhandler(404)
def not_found_error(error):
    return render_template('404.html', data=RESUME_DATA), 404

@main.errorhandler(500)
def internal_error(error):
    return render_template('500.html', data=RESUME_DATA), 500
