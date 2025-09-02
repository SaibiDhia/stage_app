package com.pfe.gestionstages.repository;

import com.pfe.gestionstages.model.FcmToken;
import com.pfe.gestionstages.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {
  Optional<FcmToken> findByUser(User user);
}
