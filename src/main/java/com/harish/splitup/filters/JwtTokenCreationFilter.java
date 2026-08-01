package com.harish.splitup.filters;

import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Calendar;
import java.util.HashMap;

public class JwtTokenCreationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final AuthenticationManager authManager;

    public JwtTokenCreationFilter(JwtService jwtService, AuthenticationManager authManager){
        this.jwtService = jwtService;
        this.authManager = authManager;
    }


    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        if(!request.getRequestURI().equals("/api/v1/login")){
            filterChain.doFilter(request, response);
            return;
        }
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(
                request.getParameter("username"),
                request.getParameter("password")
                );
        Authentication authentication = authManager.authenticate(token);
        if(authentication.isAuthenticated()){
            Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.HOUR, 24);
            SplitUser user = (SplitUser) authentication.getPrincipal();
            HashMap<String, String> claims = new HashMap<>();
            claims.put("userId", String.valueOf(user.getId()));
            String jwtToken = jwtService.createToken(claims, calendar.getTime(), user.getEmailId());
            response.setHeader("Authorization","Bearer " + jwtToken);
        }
    }
}
