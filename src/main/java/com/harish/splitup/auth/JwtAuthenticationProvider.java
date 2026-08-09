package com.harish.splitup.auth;

import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.service.JwtService;

@Component
public class JwtAuthenticationProvider implements AuthenticationProvider {

    UserDetailsService userDetailsService;

    JwtService jwtService;

    public JwtAuthenticationProvider(UserDetailsService userDetailsService, JwtService jwtService){
        this.userDetailsService = userDetailsService;
        this.jwtService = jwtService;
    }


    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        JwtAuthenticationToken jwtAuthToken = (JwtAuthenticationToken) authentication;

        if(jwtAuthToken.getToken() == null || jwtAuthToken.getToken().isEmpty()){
             throw new IllegalArgumentException("jwt token can't be null or empty");
        }
        
        String userName = this.jwtService.validateAndGetUserName(jwtAuthToken.getToken());
        if(userName == null){
            throw new BadCredentialsException("Invalid jwt token");
        }

        SplitUser user = (SplitUser) userDetailsService.loadUserByUsername(userName);
        if(user == null){
            throw new BadCredentialsException("Invalid jwt token :: user not found");
        }
        return new UsernamePasswordAuthenticationToken(user,null, user.getAuthorities());
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return JwtAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
