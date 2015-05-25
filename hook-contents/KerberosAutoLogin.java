package com.liferay.portal.security.auth;

import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.liferay.portal.model.User;
import com.liferay.portal.service.UserLocalServiceUtil;
import com.liferay.portal.util.PortalUtil;

public class KerberosAutoLogin implements AutoLogin {
	
    private final static Logger logger = Logger.getLogger(KerberosAutoLogin.class.getName());
	
    public String[] handleException(javax.servlet.http.HttpServletRequest request, javax.servlet.http.HttpServletResponse response, Exception e) 
            throws AutoLoginException {
		return doHandleException(request, response, e);
	}
	
	protected String[] doHandleException(
			HttpServletRequest request, HttpServletResponse response,
			Exception e)
		throws AutoLoginException {

		if (request.getAttribute(AutoLogin.AUTO_LOGIN_REDIRECT) == null) {
			throw new AutoLoginException(e);
		}

		logger.setLevel(Level.INFO);
		logger.info("doHandleException: " + e);

		return null;
	}
    
	public String[] login(HttpServletRequest req, HttpServletResponse res)
			throws AutoLoginException {
		try {
			return doLogin(req, res);
		}
		catch (Exception e) {
			return handleException(req, res, e);
		}
	}
	
	protected String[] doLogin(HttpServletRequest req, HttpServletResponse res)
	throws AutoLoginException, Exception {
		logger.setLevel(Level.INFO);
		String[] credentials = null;
		String userName = (String) req.getAttribute("REMOTE_USER");
		logger.info("kerberosUserName = " + userName);
		
		userName = userName.replaceAll("@.*", "").replaceAll("/.*", "");
		logger.info("userName = " + userName);
		
			long companyID = PortalUtil.getCompanyId(req);
			logger.info("CompanyID = " + companyID);
			
			if (userName == null || userName.length() < 1) {
				return credentials;
			} else {
				credentials = new String[3];
				
				User user = UserLocalServiceUtil.getUserByScreenName(companyID, userName);
				long userID = user.getUserId();
				String userPassword = user.getPassword();
				logger.info("userID = " + userID);
				
				credentials[0] = String.valueOf(userID);
				credentials[1] = userPassword;
				credentials[2] = Boolean.FALSE.toString();
				
				return credentials;	
			}
	}
}