package com.harish.splitup.filters;

import com.harish.splitup.auth.JwtAuthenticationToken;
import com.harish.splitup.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class JwtValidationFilter extends OncePerRequestFilter {

    JwtService jwtService;
    AuthenticationManager authManager;

    public JwtValidationFilter(JwtService jwtService, AuthenticationManager authManager){
        this.jwtService = jwtService;
        this.authManager = authManager;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String token = getAuthToken(request);
        if(token != null){
            JwtAuthenticationToken jwtAuthToken = new JwtAuthenticationToken(token);
            Authentication auth = this.authManager.authenticate(jwtAuthToken);
            if(auth.isAuthenticated()){
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        }
        filterChain.doFilter(request,response);
    }

    private String getAuthToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");

        if(header != null){
            return header.substring(7);
        }
        return null;
    }
}
