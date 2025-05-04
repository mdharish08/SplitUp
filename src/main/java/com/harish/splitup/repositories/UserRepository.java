package com.harish.splitup.repositories;

import com.harish.splitup.entities.SplitUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<SplitUser, Long> {

    Optional<SplitUser> findByEmailId(String emailId);
}
