package com.harish.splitup.entities;


import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.UserDto;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.util.ObjectUtils;

import java.sql.Timestamp;
import java.util.Collection;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "split_user")
@Builder(setterPrefix = "with")
@JsonIdentityInfo(generator=ObjectIdGenerators.PropertyGenerator.class, property="id")
public class SplitUser implements UserDetails, Comparable<SplitUser>{

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String firstName;

    private String lastName;

    private String phoneNumber;

    private String userPassWord;

    @Column(name = "emailId", unique = true, nullable = false)
    private String emailId;

    private int age;

    @Enumerated(EnumType.STRING)
    private AppConstants.Gender gender;

    private boolean isEmailVerified;

    private boolean trashed;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    @Override
    public boolean equals(Object obj){
        if(!(obj instanceof SplitUser user)){
            return false;
        }
        return this.getId().equals(user.getId()) && this.getEmailId().equals(user.getEmailId());
    }

    @Override
    public int hashCode(){
        return ObjectUtils.nullSafeHash(this.getId(),this.getEmailId());
    }


    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of();
    }

    @Override
    public String getPassword() {
        return this.getUserPassWord();
    }

    @Override
    public String getUsername() {
       return this.getEmailId();
    }

    @Override
    public boolean isAccountNonExpired() {
        return !this.isTrashed();
    }

    @Override
    public boolean isAccountNonLocked() {
        return UserDetails.super.isAccountNonLocked();
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return UserDetails.super.isCredentialsNonExpired();
    }

    @Override
    public boolean isEnabled() {
        return UserDetails.super.isEnabled();
    }

    public UserDto toDTO() {
        UserDto dto = new UserDto();
        dto.setId(this.getId());
        dto.setFirstName(this.getFirstName());
        dto.setLastName(this.getLastName());
        dto.setEmailId(this.getEmailId());
        dto.setRegistrationStatus(this.isEmailVerified() ? "verified" : "not_verified");
        dto.setUpdatedAt(this.getUpdatedAt());
        return dto;
    }

    @Override
    public int compareTo(SplitUser user) {
       if(user == null){
           return 0;
       }
       return Long.compare(this.getId(),user.getId());
    }
}
