"""
Advanced Professional Security System for Portfolio Resume Downloads
Implements enterprise-grade verification tailored for professional contexts
"""

import re
import requests
import time
import hashlib
import json
from datetime import datetime, timedelta
from flask import request, session, current_app
from functools import wraps
import user_agents

class ProfessionalSecurityManager:
    """Advanced security manager for professional portfolio access"""
    
    def __init__(self):
        self.corporate_domains = {
            # Tech Giants
            'google.com', 'microsoft.com', 'apple.com', 'amazon.com', 'meta.com',
            'netflix.com', 'uber.com', 'airbnb.com', 'spotify.com', 'zoom.us',
            
            # Consulting & Professional Services
            'mckinsey.com', 'bcg.com', 'bain.com', 'deloitte.com', 'pwc.com',
            'ey.com', 'kpmg.com', 'accenture.com', 'ibm.com', 'oracle.com',
            
            # Financial Services
            'jpmorgan.com', 'goldmansachs.com', 'morganstanley.com', 'blackrock.com',
            'citi.com', 'wellsfargo.com', 'bankofamerica.com', 'chase.com',
            
            # Healthcare & Pharma
            'pfizer.com', 'jnj.com', 'roche.com', 'novartis.com', 'merck.com',
            
            # Aerospace & Defense
            'boeing.com', 'lockheedmartin.com', 'raytheon.com', 'northropgrumman.com',
            
            # Automotive
            'tesla.com', 'ford.com', 'gm.com', 'toyota.com', 'bmw.com',
            
            # Common corporate email patterns
            'corp.com', 'company.com', 'inc.com', 'ltd.com', 'llc.com'
        }
        
        self.professional_indicators = {
            'high_value': ['ceo', 'cto', 'vp', 'director', 'manager', 'lead', 'senior', 'principal'],
            'tech_roles': ['engineer', 'developer', 'architect', 'devops', 'sre', 'data', 'ml', 'ai'],
            'business_roles': ['analyst', 'consultant', 'strategy', 'product', 'marketing', 'sales'],
            'hr_recruiting': ['recruiter', 'hr', 'talent', 'hiring', 'people', 'recruitment']
        }
    
    def analyze_professional_context(self, email=None, user_agent=None, referrer=None):
        """Analyze the professional context of the access request"""
        context_score = 0
        context_details = {
            'email_score': 0,
            'domain_type': 'unknown',
            'device_type': 'unknown',
            'access_pattern': 'standard',
            'professional_indicators': [],
            'risk_level': 'medium'
        }
        
        # Email domain analysis
        if email:
            domain = email.split('@')[-1].lower()
            context_details['domain'] = domain
            
            if domain in self.corporate_domains:
                context_score += 30
                context_details['email_score'] = 30
                context_details['domain_type'] = 'corporate'
            elif self._is_corporate_pattern(domain):
                context_score += 20
                context_details['email_score'] = 20
                context_details['domain_type'] = 'business'
            elif domain in ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com']:
                context_score += 5
                context_details['email_score'] = 5
                context_details['domain_type'] = 'personal'
            
            # Check for professional indicators in email
            email_lower = email.lower()
            for category, indicators in self.professional_indicators.items():
                for indicator in indicators:
                    if indicator in email_lower:
                        context_score += 10
                        context_details['professional_indicators'].append(f"{category}:{indicator}")
        
        # User agent analysis
        if user_agent:
            ua = user_agents.parse(user_agent)
            if ua.is_mobile:
                context_details['device_type'] = 'mobile'
                context_score += 5  # Mobile access is common for professionals
            elif ua.is_tablet:
                context_details['device_type'] = 'tablet'
                context_score += 8
            else:
                context_details['device_type'] = 'desktop'
                context_score += 15  # Desktop access suggests professional context
        
        # Referrer analysis
        if referrer:
            professional_referrers = ['linkedin.com', 'indeed.com', 'glassdoor.com', 'monster.com']
            for prof_ref in professional_referrers:
                if prof_ref in referrer.lower():
                    context_score += 25
                    context_details['access_pattern'] = 'professional_referral'
                    break
        
        # Risk assessment
        if context_score >= 50:
            context_details['risk_level'] = 'low'
        elif context_score >= 25:
            context_details['risk_level'] = 'medium'
        else:
            context_details['risk_level'] = 'high'
        
        context_details['total_score'] = context_score
        return context_details
    
    def _is_corporate_pattern(self, domain):
        """Check if domain follows corporate patterns"""
        corporate_patterns = [
            r'.*corp\.com$',
            r'.*company\.com$',
            r'.*inc\.com$',
            r'.*ltd\.com$',
            r'.*llc\.com$',
            r'.*group\.com$',
            r'.*consulting\.com$',
            r'.*solutions\.com$',
            r'.*tech\.com$',
            r'.*systems\.com$'
        ]
        
        for pattern in corporate_patterns:
            if re.match(pattern, domain):
                return True
        return False
    
    def generate_professional_challenge(self, context):
        """Generate context-appropriate security challenge"""
        challenges = {
            'low_risk': {
                'type': 'minimal',
                'message': 'Professional Access Verified',
                'action': 'proceed'
            },
            'medium_risk': {
                'type': 'email_verification',
                'message': 'Please verify your professional email',
                'action': 'email_verify'
            },
            'high_risk': {
                'type': 'enhanced_verification',
                'message': 'Enhanced verification required',
                'action': 'multi_step'
            }
        }
        
        return challenges.get(context['risk_level'], challenges['medium_risk'])
    
    def create_professional_access_token(self, context, email=None):
        """Create a professional access token with context"""
        token_data = {
            'timestamp': time.time(),
            'context_score': context['total_score'],
            'domain_type': context['domain_type'],
            'risk_level': context['risk_level'],
            'email_hash': hashlib.sha256(email.encode()).hexdigest()[:16] if email else None,
            'expires': (datetime.now() + timedelta(minutes=10)).timestamp()
        }
        
        # Create secure token
        token_string = json.dumps(token_data, sort_keys=True)
        token_hash = hashlib.sha256(token_string.encode()).hexdigest()[:32]
        
        return token_hash, token_data

class ProfessionalVerificationDecorator:
    """Decorator for professional verification"""
    
    @staticmethod
    def require_professional_verification(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            security_manager = ProfessionalSecurityManager()
            
            # Analyze context
            context = security_manager.analyze_professional_context(
                email=request.form.get('email'),
                user_agent=request.headers.get('User-Agent'),
                referrer=request.headers.get('Referer')
            )
            
            # Store context in session
            session['professional_context'] = context
            
            return f(*args, **kwargs)
        return decorated_function

# Professional verification challenges
PROFESSIONAL_CHALLENGES = {
    'industry_knowledge': [
        {
            'question': 'What does "CI/CD" stand for in software development?',
            'options': ['Continuous Integration/Continuous Deployment', 'Code Integration/Code Deployment', 'Central Integration/Central Deployment'],
            'correct': 0,
            'category': 'tech'
        },
        {
            'question': 'What is the primary purpose of a load balancer?',
            'options': ['Store data', 'Distribute traffic across servers', 'Encrypt communications'],
            'correct': 1,
            'category': 'tech'
        },
        {
            'question': 'In project management, what does "MVP" typically mean?',
            'options': ['Most Valuable Player', 'Minimum Viable Product', 'Maximum Value Proposition'],
            'correct': 1,
            'category': 'business'
        }
    ],
    'professional_context': [
        {
            'question': 'You are accessing this resume for:',
            'options': ['Job opportunity evaluation', 'Academic research', 'Personal interest', 'Competitive analysis'],
            'category': 'intent'
        }
    ]
}

def get_contextual_challenge(context):
    """Get appropriate challenge based on professional context"""
    if context['domain_type'] == 'corporate' and context['total_score'] > 40:
        return None  # Skip challenge for high-trust corporate users
    elif 'tech' in str(context['professional_indicators']):
        return PROFESSIONAL_CHALLENGES['industry_knowledge'][0]  # Tech question
    elif 'business' in str(context['professional_indicators']):
        return PROFESSIONAL_CHALLENGES['industry_knowledge'][2]  # Business question
    else:
        return PROFESSIONAL_CHALLENGES['professional_context'][0]  # Intent question
