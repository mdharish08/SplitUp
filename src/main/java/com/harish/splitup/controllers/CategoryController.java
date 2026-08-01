package com.harish.splitup.controllers;

import com.harish.splitup.dto.CategoryDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.repositories.CategoryRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/categories")
public class CategoryController {

    private final CategoryRepository categoryRepository;

    public CategoryController(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @GetMapping
    public ResponseEntity<ResponseDto<List<CategoryDto>>> getAll() {
        List<CategoryDto> data = categoryRepository.findAll().stream()
                .map(c -> c.toDTO())
                .toList();
        return ResponseEntity.ok(ResponseDto.success(data));
    }
}
