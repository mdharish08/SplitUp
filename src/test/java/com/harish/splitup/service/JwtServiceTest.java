package com.harish.splitup.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService("abcdefghijklmnopqrstuvwxyz012345");
    }

    @Test
    void createToken_andValidate_returnsSubject() {
        Map<String, String> claims = new HashMap<>();
        claims.put("userId", "42");
        String token = jwtService.createToken(claims, new Date(System.currentTimeMillis() + 60_000), "alice@example.com");

        assertThat(jwtService.validateAndGetUserName(token)).isEqualTo("alice@example.com");
    }

    @Test
    void validateExpiredToken_returnsNull() {
        String token = jwtService.createToken(Map.of(), new Date(System.currentTimeMillis() - 60_000), "alice@example.com");

        assertThat(jwtService.validateAndGetUserName(token)).isNull();
    }

    @Test
    void validateInvalidToken_returnsNull() {
        assertThat(jwtService.validateAndGetUserName("not-a-token")).isNull();
    }
}
