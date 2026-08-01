package com.harish.splitup.controllers;

import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/v1")
public class AuthController {

    @Autowired
    UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<ResponseDto<UserDto>> signup(@RequestBody SignupRequestDto req) {
        try {
            UserDto created = userService.registerUser(req);
            return ResponseEntity.status(HttpStatus.CREATED).body(ResponseDto.success(created));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ResponseDto.error(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }
}
