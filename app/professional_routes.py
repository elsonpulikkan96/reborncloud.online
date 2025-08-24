"""
Advanced Professional Verification Routes
Enterprise-grade security for portfolio resume access
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session, current_app, jsonify
from .professional_security import ProfessionalSecurityManager, get_contextual_challenge
from .routes import limiter, log_download_attempt, generate_download_token, verify_recaptcha
import time
import json

professional = Blueprint('professional', __name__)

@professional.route('/professional-resume-access')
@limiter.limit("10 per minute")
def professional_resume_access():
    """Advanced professional resume access page"""
    recaptcha_site_key = current_app.config.get('RECAPTCHA_SITE_KEY')
    return render_template('professional_resume_access.html', 
                         recaptcha_site_key=recaptcha_site_key)

@professional.route('/professional-verify-access', methods=['POST'])
@limiter.limit("5 per minute")
def professional_verify_access():
    """Advanced professional verification with context analysis"""
    ip_address = request.environ.get('REMOTE_ADDR', 'unknown')
    
    try:
        # Initialize security manager
        security_manager = ProfessionalSecurityManager()
        
        # Get form data
        professional_email = request.form.get('professional_email', '').strip()
        company = request.form.get('company', '').strip()
        role = request.form.get('role', '').strip()
        purpose = request.form.get('purpose', '').strip()
        user_agent = request.headers.get('User-Agent')
        referrer = request.headers.get('Referer')
        
        # Validate required fields
        if not professional_email or not purpose:
            log_download_attempt(ip_address, False, "Missing required professional information")
            flash('Please provide your professional email and access purpose.', 'error')
            return redirect(url_for('professional.professional_resume_access'))
        
        # Analyze professional context
        context = security_manager.analyze_professional_context(
            email=professional_email,
            user_agent=user_agent,
            referrer=referrer
        )
        
        # Add form data to context
        context['form_data'] = {
            'email': professional_email,
            'company': company,
            'role': role,
            'purpose': purpose
        }
        
        # Enhanced scoring based on form data
        context_score_bonus = 0
        
        # Role-based scoring
        high_value_roles = ['recruiter', 'hiring_manager', 'cto_vp', 'tech_lead']
        if role in high_value_roles:
            context_score_bonus += 15
        
        # Purpose-based scoring
        professional_purposes = ['job_opportunity', 'consulting_project', 'partnership']
        if purpose in professional_purposes:
            context_score_bonus += 10
        
        # Company information bonus
        if company:
            context_score_bonus += 5
        
        context['total_score'] += context_score_bonus
        context['form_bonus'] = context_score_bonus
        
        # Re-evaluate risk level with enhanced scoring
        if context['total_score'] >= 60:
            context['risk_level'] = 'low'
        elif context['total_score'] >= 35:
            context['risk_level'] = 'medium'
        else:
            context['risk_level'] = 'high'
        
        # Check professional challenge (if required)
        challenge_answer = request.form.get('challenge_answer')
        challenge_correct = request.form.get('challenge_correct')
        
        if challenge_answer is not None and challenge_correct is not None:
            if int(challenge_answer) != int(challenge_correct):
                log_download_attempt(ip_address, False, "Professional challenge failed")
                flash('Professional verification challenge failed. Please try again.', 'error')
                return redirect(url_for('professional.professional_resume_access'))
            else:
                context['challenge_passed'] = True
                context['total_score'] += 10  # Bonus for passing challenge
        
        # reCAPTCHA verification (if configured)
        recaptcha_configured = bool(current_app.config.get('RECAPTCHA_SECRET_KEY'))
        
        if recaptcha_configured:
            recaptcha_response = request.form.get('g-recaptcha-response')
            if not verify_recaptcha(recaptcha_response):
                log_download_attempt(ip_address, False, "reCAPTCHA verification failed")
                flash('reCAPTCHA verification failed. Please try again.', 'error')
                return redirect(url_for('professional.professional_resume_access'))
        
        # Generate professional access token
        token, token_data = security_manager.create_professional_access_token(
            context, professional_email
        )
        
        # Store verification data in session
        session['professional_verification'] = {
            'verified': True,
            'timestamp': time.time(),
            'context': context,
            'token': token
        }
        
        # Log successful verification
        log_message = f"Professional access verified - Score: {context['total_score']}, Risk: {context['risk_level']}, Domain: {context['domain_type']}"
        log_download_attempt(ip_address, True, log_message)
        
        # Success message based on context
        if context['risk_level'] == 'low':
            flash('Professional verification successful! High-trust access granted.', 'success')
        elif context['risk_level'] == 'medium':
            flash('Professional verification successful! Standard access granted.', 'success')
        else:
            flash('Verification successful! Enhanced security protocols applied.', 'success')
        
        # Redirect to download with professional token
        return redirect(url_for('main.download_resume', token=token))
        
    except Exception as e:
        current_app.logger.error(f"Professional verification error: {str(e)}")
        log_download_attempt(ip_address, False, f"Professional verification system error: {str(e)}")
        flash('Professional verification system temporarily unavailable. Please try again.', 'error')
        return redirect(url_for('professional.professional_resume_access'))

@professional.route('/professional-context-analysis', methods=['POST'])
@limiter.limit("20 per minute")
def professional_context_analysis():
    """AJAX endpoint for real-time professional context analysis"""
    try:
        data = request.get_json()
        email = data.get('email', '')
        
        if not email:
            return jsonify({'error': 'Email required'}), 400
        
        security_manager = ProfessionalSecurityManager()
        context = security_manager.analyze_professional_context(
            email=email,
            user_agent=request.headers.get('User-Agent'),
            referrer=request.headers.get('Referer')
        )
        
        # Get appropriate challenge
        challenge = get_contextual_challenge(context)
        
        response = {
            'context': {
                'domain_type': context['domain_type'],
                'email_score': context['email_score'],
                'risk_level': context['risk_level'],
                'total_score': context['total_score']
            },
            'challenge': challenge,
            'recommendations': get_access_recommendations(context)
        }
        
        return jsonify(response)
        
    except Exception as e:
        current_app.logger.error(f"Context analysis error: {str(e)}")
        return jsonify({'error': 'Analysis failed'}), 500

def get_access_recommendations(context):
    """Get access recommendations based on professional context"""
    recommendations = []
    
    if context['domain_type'] == 'corporate':
        recommendations.append({
            'type': 'success',
            'message': 'Corporate email detected - Priority access available'
        })
    elif context['domain_type'] == 'business':
        recommendations.append({
            'type': 'info',
            'message': 'Business email detected - Standard verification process'
        })
    elif context['domain_type'] == 'personal':
        recommendations.append({
            'type': 'warning',
            'message': 'Personal email - Enhanced verification required'
        })
    
    if context['risk_level'] == 'low':
        recommendations.append({
            'type': 'success',
            'message': 'High-trust profile - Streamlined access process'
        })
    elif context['risk_level'] == 'high':
        recommendations.append({
            'type': 'info',
            'message': 'Additional verification steps may be required'
        })
    
    return recommendations

# Professional verification statistics (for admin/monitoring)
@professional.route('/professional-stats')
@limiter.limit("10 per minute")
def professional_stats():
    """Professional verification statistics (admin only)"""
    # This would typically require admin authentication
    # For now, return basic stats
    
    stats = {
        'total_verifications': session.get('verification_count', 0),
        'corporate_access': session.get('corporate_count', 0),
        'challenge_success_rate': session.get('challenge_success_rate', 0),
        'average_context_score': session.get('avg_context_score', 0)
    }
    
    return jsonify(stats)
