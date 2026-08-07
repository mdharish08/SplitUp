package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.GroupMapping;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.GroupMappingRepository;
import com.harish.splitup.repositories.GroupRepository;
import com.harish.splitup.repositories.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class GroupServiceTest {

    @Mock private GroupRepository groupRepository;
    @Mock private UserRepository userRepository;
    @Mock private GroupMappingRepository groupMappingRepository;
    @Mock private BalanceRepository balanceRepository;

    @InjectMocks
    private GroupService groupService;

    private SplitUser creator;
    private SplitUser member1;
    private SplitUser member2;

    @BeforeEach
    void setUp() {
        creator = SplitUser.builder()
                .withId(1L).withFirstName("Alice").withLastName("Smith")
                .withEmailId("alice@example.com").withUserPassWord("encoded").build();

        member1 = SplitUser.builder()
                .withId(2L).withFirstName("Bob").withLastName("Jones")
                .withEmailId("bob@example.com").withUserPassWord("encoded").build();

        member2 = SplitUser.builder()
                .withId(3L).withFirstName("Carol").withLastName("White")
                .withEmailId("carol@example.com").withUserPassWord("encoded").build();
    }

    private UserGroupMeta buildGroupMeta(String name, String groupType, String currencyCode,
                                          List<Long> memberIds) {
        UserGroupMeta meta = new UserGroupMeta();
        meta.setName(name);
        meta.setGroupType(groupType);
        meta.setCurrencyCode(currencyCode);
        meta.setDescription("Test group");

        List<UserGroupMeta.GroupMemberMeta> members = new ArrayList<>();
        for (Long id : memberIds) {
            UserGroupMeta.GroupMemberMeta m = new UserGroupMeta.GroupMemberMeta();
            m.setId(id);
            members.add(m);
        }
        meta.setMembers(members);
        return meta;
    }

    // ── createGroup ───────────────────────────────────────────────────────────

    @Test
    void createGroup_happyPath_savesGroupMappingsAndBalances() {
        // given
        UserGroupMeta meta = buildGroupMeta("Weekend Trip", "TRIP", "USD",
                List.of(1L, 2L, 3L));

        given(userRepository.findById(1L)).willReturn(Optional.of(creator));
        given(userRepository.findAllById(List.of(1L, 2L, 3L)))
                .willReturn(List.of(creator, member1, member2));

        // when
        UserGroupMeta result = groupService.createGroup(1L, meta);

        // then
        then(groupRepository).should(times(1)).save(any(Group.class));
        then(groupMappingRepository).should(times(1)).saveAll(anyList());
        then(balanceRepository).should(times(1)).saveAll(anyList());
        assertThat(result.getName()).isEqualTo("Weekend Trip");
        assertThat(result.getMembers()).hasSize(3);
    }

    @Test
    void createGroup_missingName_throwsIllegalArgument() {
        UserGroupMeta meta = buildGroupMeta("", "TRIP", "USD", List.of(1L, 2L));

        assertThatThrownBy(() -> groupService.createGroup(1L, meta))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Group name is required");
    }

    @Test
    void createGroup_emptyMembers_throwsIllegalArgument() {
        UserGroupMeta meta = buildGroupMeta("My Group", "HOME", "USD", List.of());

        assertThatThrownBy(() -> groupService.createGroup(1L, meta))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("At least one member is required");
    }

    @Test
    void createGroup_invalidGroupType_throwsIllegalArgument() {
        UserGroupMeta meta = buildGroupMeta("My Group", "INVALID_TYPE", "USD", List.of(1L, 2L));

        assertThatThrownBy(() -> groupService.createGroup(1L, meta))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid groupType");
    }

    @Test
    void createGroup_memberNotFound_throwsIllegalArgument() {
        // given – only 1 of the 2 requested members is found
        UserGroupMeta meta = buildGroupMeta("My Group", "HOME", "USD", List.of(2L, 99L));
        given(userRepository.findById(1L)).willReturn(Optional.of(creator));
        given(userRepository.findAllById(List.of(2L, 99L))).willReturn(List.of(member1)); // one missing

        assertThatThrownBy(() -> groupService.createGroup(1L, meta))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("One or more members not found");
    }

    @Test
    @SuppressWarnings("unchecked")
    void createGroup_createsNxNBalanceRecords() {
        // given – 3 members → 3*(3-1) = 6 balance rows
        UserGroupMeta meta = buildGroupMeta("Team", "OTHER", "USD", List.of(1L, 2L, 3L));
        given(userRepository.findById(1L)).willReturn(Optional.of(creator));
        given(userRepository.findAllById(List.of(1L, 2L, 3L)))
                .willReturn(List.of(creator, member1, member2));

        // when
        groupService.createGroup(1L, meta);

        // then – capture the balances list and verify count
        ArgumentCaptor<List<Balance>> captor = ArgumentCaptor.forClass(List.class);
        then(balanceRepository).should().saveAll(captor.capture());
        List<Balance> savedBalances = captor.getValue();
        assertThat(savedBalances).hasSize(6); // n*(n-1) = 3*2 = 6
    }
}
