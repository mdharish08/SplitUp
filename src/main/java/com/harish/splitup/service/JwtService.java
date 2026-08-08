package com.harish.splitup.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {

    private final SecretKey key;

    public JwtService(@Value("${jwt.secret}") String secret) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String createToken(Map<String, String> claims, Date expiration, String subject) {
        return Jwts.builder()
                .claims()
                .add(claims)
                .expiration(expiration)
                .subject(subject)
                .issuedAt(new Date())
                .and()
                .signWith(key)
                .compact();
    }

    public String validateAndGetUserName(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            Date expiration = claims.getExpiration();
            if (expiration == null || !expiration.after(new Date())) {
                return null;
            }
            return claims.getSubject();
        } catch (JwtException e) {
            return null;
        }
    }
}
