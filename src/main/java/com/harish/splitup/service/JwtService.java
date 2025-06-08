package com.harish.splitup.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {

    private final String secret = "b1gkFvO12Rukv31wSpQMdMn5/9vCk+LWshH/VKKObeI=";

    private final SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));

    public String createToken(Map<String,String> claims , Date expiration, String subject){
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

    public String validateAndGetUserName(String token){
        JwtParser parser = Jwts.parser()
                .verifyWith(key)
                .build();
        Jws<Claims> jwt =  parser.parseSignedClaims(token);
        Claims claims = jwt.getPayload();
        Date expiration = claims.getExpiration();
        if(expiration.after(new Date())){
            return claims.getSubject();
        }
        return null;
    }
}
