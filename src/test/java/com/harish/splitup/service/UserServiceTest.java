package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock private FriendsRepository friendsRepository;
    @Mock private BalanceRepository balanceRepository;
    @Mock private UserRepository userRepository;
    @Mock private GroupMappingRepository groupMappingRepository;
    @Mock private GroupRepository groupRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private PendingFriendInviteRepository pendingInviteRepository;

    @InjectMocks
    private UserService userService;

    private SplitUser alice;
    private SplitUser bob;

    @BeforeEach
    void setUp() {
        alice = SplitUser.builder()
                .withId(1L)
                .withFirstName("Alice")
                .withLastName("Smith")
                .withEmailId("alice@example.com")
                .withUserPassWord("encoded-pw")
                .withAccountStatus(AppConstants.AccountStatus.ACTIVE)
                .build();

        bob = SplitUser.builder()
                .withId(2L)
                .withFirstName("Bob")
                .withLastName("Jones")
                .withEmailId("bob@example.com")
                .withUserPassWord("encoded-pw")
                .withAccountStatus(AppConstants.AccountStatus.ACTIVE)
                .build();
    }

    private SignupRequestDto signupRequest(String email) {
        SignupRequestDto req = new SignupRequestDto();
        req.setFirstName("Alice");
        req.setLastName("Smith");
        req.setEmailId(email);
        req.setPassword("secret123");
        return req;
    }

    private AddFriendRequestDto addFriendRequest(String email) {
        AddFriendRequestDto req = new AddFriendRequestDto();
        req.setEmailId(email);
        req.setCurrencyCode("USD");
        return req;
    }

    // ── registerUser ──────────────────────────────────────────────────────────

    @Test
    void registerUser_happyPath_savesUserAndReturnDto() {
        // given
        SignupRequestDto req = signupRequest("alice@example.com");
        given(userRepository.findByEmailId("alice@example.com")).willReturn(Optional.empty());
        given(passwordEncoder.encode("secret123")).willReturn("hashed");
        given(userRepository.save(any(SplitUser.class))).willAnswer(i -> {
            SplitUser saved = i.getArgument(0);
            if (saved.getId() == null) {
                saved.setId(100L);
            }
            return saved;
        });
        given(pendingInviteRepository.findAllByInviteeEmail("alice@example.com"))
                .willReturn(List.of());

        // when
        UserDto result = userService.registerUser(req);

        // then
        then(userRepository).should(times(1)).save(any(SplitUser.class));
        assertThat(result.getFirstName()).isEqualTo("Alice");
        assertThat(result.getEmailId()).isEqualTo("alice@example.com");
    }

    @Test
    void registerUser_duplicateEmail_throwsIllegalState() {
        // given
        SignupRequestDto req = signupRequest("alice@example.com");
        alice.setAccountStatus(AppConstants.AccountStatus.ACTIVE);
        given(userRepository.findByEmailId("alice@example.com")).willReturn(Optional.of(alice));

        // when / then
        assertThatThrownBy(() -> userService.registerUser(req))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("already registered");

        then(userRepository).should(never()).save(any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void registerUser_withPendingInvites_convertsThem() {
        // given
        SignupRequestDto req = signupRequest("newuser@example.com");

        SplitUser inviter = SplitUser.builder()
                .withId(10L)
                .withFirstName("Inviter")
                .withLastName("Person")
                .withEmailId("inviter@example.com")
                .withUserPassWord("encoded")
                .build();

        PendingFriendInvite invite = PendingFriendInvite.builder()
                .withInviter(inviter)
                .withInviteeEmail("newuser@example.com")
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .withCreatedAt(new Timestamp(System.currentTimeMillis()))
                .build();

        given(userRepository.findByEmailId("newuser@example.com")).willReturn(Optional.empty());
        given(passwordEncoder.encode("secret123")).willReturn("hashed");
        given(userRepository.save(any(SplitUser.class))).willAnswer(i -> {
            SplitUser saved = i.getArgument(0);
            if (saved.getId() == null) {
                saved.setId(101L);
            }
            return saved;
        });
        given(pendingInviteRepository.findAllByInviteeEmail("newuser@example.com"))
                .willReturn(List.of(invite));

        // when
        userService.registerUser(req);

        // then – friendship and balances created; pending invite deleted
        then(friendsRepository).should(times(1)).saveAll(anyList());
        then(balanceRepository).should(times(1)).saveAll(anyList());
        then(pendingInviteRepository).should(times(1)).deleteAll(anyList());
    }

    @Test
    void registerUser_existingInvitedUser_upgradesSameAccount() {
        SignupRequestDto req = signupRequest("invited@example.com");
        SplitUser invited = SplitUser.builder()
                .withId(42L)
                .withEmailId("invited@example.com")
                .withFirstName("invited@example.com")
                .withUserPassWord("placeholder")
                .withAccountStatus(AppConstants.AccountStatus.INVITED)
                .build();

        given(userRepository.findByEmailId("invited@example.com")).willReturn(Optional.of(invited));
        given(passwordEncoder.encode("secret123")).willReturn("hashed");
        given(userRepository.save(any(SplitUser.class))).willAnswer(i -> i.getArgument(0));
        given(pendingInviteRepository.findAllByInviteeEmail("invited@example.com")).willReturn(List.of());

        UserDto result = userService.registerUser(req);

        then(userRepository).should(times(1)).save(invited);
        assertThat(invited.getAccountStatus()).isEqualTo(AppConstants.AccountStatus.ACTIVE);
        assertThat(invited.getFirstName()).isEqualTo("Alice");
        assertThat(result.getId()).isEqualTo(42L);
        assertThat(result.getRegistrationStatus()).isEqualTo("not_verified");
    }

    // ── addFriend ─────────────────────────────────────────────────────────────

    @Test
    void addFriend_registeredUser_createsFriendshipAndBalances() {
        // given
        given(userRepository.findById(1L)).willReturn(Optional.of(alice));
        given(userRepository.findByEmailId("bob@example.com")).willReturn(Optional.of(bob));
        given(friendsRepository.findExisting(1L, 2L)).willReturn(Optional.empty());

        // when
        FriendsDto result = userService.addFriend(1L, addFriendRequest("bob@example.com"));

        // then
        then(friendsRepository).should(times(1)).save(any(Friends.class));
        then(balanceRepository).should(times(1)).saveAll(anyList());
        assertThat(result.getEmailId()).isEqualTo("bob@example.com");
        assertThat(result.getRegistrationStatus()).isNotEqualTo("pending");
    }

    @Test
    void addFriend_unregisteredUser_createsInvitedUserAndFriendship() {
        // given – friend email not in the system
        given(userRepository.findById(1L)).willReturn(Optional.of(alice));
        given(userRepository.findByEmailId("stranger@example.com")).willReturn(Optional.empty());
        SplitUser invited = SplitUser.builder()
                .withId(99L)
                .withEmailId("stranger@example.com")
                .withFirstName("stranger@example.com")
                .withAccountStatus(AppConstants.AccountStatus.INVITED)
                .withUserPassWord("tmp")
                .build();
        given(userRepository.save(any(SplitUser.class))).willReturn(invited);
        given(friendsRepository.findExisting(1L, 99L)).willReturn(Optional.empty());

        // when
        FriendsDto result = userService.addFriend(1L, addFriendRequest("stranger@example.com"));

        // then
        then(userRepository).should(times(1)).save(any(SplitUser.class));
        then(friendsRepository).should(times(1)).save(any(Friends.class));
        then(balanceRepository).should(times(1)).saveAll(anyList());
        assertThat(result.getRegistrationStatus()).isEqualTo("pending");
        assertThat(result.getEmailId()).isEqualTo("stranger@example.com");
    }

    @Test
    void addFriend_normalizesInviteEmailBeforeLookup() {
        given(userRepository.findById(1L)).willReturn(Optional.of(alice));
        given(userRepository.findByEmailId("stranger@example.com")).willReturn(Optional.empty());
        SplitUser invited = SplitUser.builder()
                .withId(99L)
                .withEmailId("stranger@example.com")
                .withFirstName("stranger@example.com")
                .withAccountStatus(AppConstants.AccountStatus.INVITED)
                .withUserPassWord("tmp")
                .build();
        given(userRepository.save(any(SplitUser.class))).willReturn(invited);
        given(friendsRepository.findExisting(1L, 99L)).willReturn(Optional.empty());

        userService.addFriend(1L, addFriendRequest("  Stranger@Example.com "));

        then(userRepository).should(times(1)).findByEmailId("stranger@example.com");
    }

    @Test
    void addFriend_selfAdd_throwsIllegalArgument() {
        // given
        given(userRepository.findById(1L)).willReturn(Optional.of(alice));

        // when / then – trying to add own email
        assertThatThrownBy(() -> userService.addFriend(1L, addFriendRequest("alice@example.com")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("yourself");
    }

    @Test
    void addFriend_alreadyFriends_throwsIllegalState() {
        // given
        Friends existingFriendship = Friends.builder()
                .withUser(alice)
                .withFriend(bob)
                .withCreatedAt(new Timestamp(System.currentTimeMillis()))
                .withUpdatedAt(new Timestamp(System.currentTimeMillis()))
                .withTrashed(false)
                .build();

        given(userRepository.findById(1L)).willReturn(Optional.of(alice));
        given(userRepository.findByEmailId("bob@example.com")).willReturn(Optional.of(bob));
        given(friendsRepository.findExisting(1L, 2L)).willReturn(Optional.of(existingFriendship));

        // when / then
        assertThatThrownBy(() -> userService.addFriend(1L, addFriendRequest("bob@example.com")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("already friends");
    }

    // ── getFriendsMeta ────────────────────────────────────────────────────────

    @Test
    void getFriendsMeta_returnsFriendsWithBalancesAndPending() {
        // given – one registered friend + one pending invite
        Friends friendship = Friends.builder()
                .withUser(alice)
                .withFriend(bob)
                .withCreatedAt(new Timestamp(System.currentTimeMillis()))
                .withUpdatedAt(new Timestamp(System.currentTimeMillis()))
                .withTrashed(false)
                .build();

        Balance personalBalance = Balance.builder()
                .withUser(alice)
                .withFriend(bob)
                .withAmount(new BigDecimal("25.00"))
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .build();

        PendingFriendInvite invite = PendingFriendInvite.builder()
                .withInviter(alice)
                .withInviteeEmail("pending@example.com")
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .withCreatedAt(new Timestamp(System.currentTimeMillis()))
                .build();

        given(friendsRepository.findAllByUserId(1L)).willReturn(List.of(friendship));
        given(balanceRepository.findAllByUserId(1L)).willReturn(List.of(personalBalance));
        given(pendingInviteRepository.findAllByInviterId(1L)).willReturn(List.of(invite));

        // when
        List<FriendsDto> result = userService.getFriendsMeta(1L);

        // then – 2 entries: bob (registered) + pending@example.com
        assertThat(result).hasSize(2);
        FriendsDto registeredEntry = result.stream()
                .filter(f -> "bob@example.com".equals(f.getEmailId()))
                .findFirst().orElseThrow();
        assertThat(registeredEntry.getBalanceDto()).isNotNull();
        assertThat(registeredEntry.getBalanceDto().getAmount()).isEqualByComparingTo("25.00");

        FriendsDto pendingEntry = result.stream()
                .filter(f -> "pending@example.com".equals(f.getEmailId()))
                .findFirst().orElseThrow();
        assertThat(pendingEntry.getRegistrationStatus()).isEqualTo("pending");
    }
}
