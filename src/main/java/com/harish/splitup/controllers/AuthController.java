package com.harish.splitup.controllers;

import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/v1")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<ResponseDto<UserDto>> signup(@RequestBody SignupRequestDto req) {
        UserDto created = userService.registerUser(req);
        return ResponseEntity.status(201).body(ResponseDto.success(created));
    }
}
