package com.harish.splitup.entities;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import jakarta.persistence.*;
import lombok.Builder;
import lombok.Data;

@Data
@Entity
@Table(name = "group_members")
@Builder(setterPrefix = "with")
@JsonIdentityInfo(generator= ObjectIdGenerators.PropertyGenerator.class, property="mappingId")
public class GroupMapping {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long mappingId;

    private long groupId;

    private long memberId;
}
