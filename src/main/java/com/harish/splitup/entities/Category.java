package com.harish.splitup.entities;

import com.harish.splitup.dto.CategoryDto;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long categoryId;

    private String name;

    public CategoryDto toDTO() {
        CategoryDto dto = new CategoryDto();
        dto.setCategoryId(this.getCategoryId());
        dto.setCategoryName(this.getName());
        return dto;
    }
}
