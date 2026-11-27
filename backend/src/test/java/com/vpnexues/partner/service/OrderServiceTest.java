package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.config.AppProperties;
import com.vpnexues.partner.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    private static final String ORDER_ID = "11111111-1111-4111-8111-111111111111";
    private static final String PARTNER_ID = "22222222-2222-4222-8222-222222222222";

    @Mock
    private Db db;
    @Mock
    private CurrentUser current;
    @Mock
    private AppProperties props;

    private OrderService service;

    @BeforeEach
    void setUp() {
        service = new OrderService(db, current, props);
    }

    @Test
    void rejectsUnknownTabAndOutOfRangeLimit() {
        ApiException tab = assertThrows(ApiException.class, () -> service.list("bogus", "today", 30));
        assertEquals("INVALID_TAB", tab.code());

        ApiException limit = assertThrows(ApiException.class, () -> service.list("active", "today", 0));
        assertEquals("INVALID_LIMIT", limit.code());
    }

    @Test
    void detailIsAlwaysScopedToTheSignedInPartner() {
        when(current.partnerId()).thenReturn(PARTNER_ID);
        when(props.trialMode()).thenReturn(false);
        when(db.one(anyString(), any(), any(), any())).thenReturn(null);

        ApiException error = assertThrows(ApiException.class, () -> service.detail(ORDER_ID));
        assertEquals("NOT_FOUND", error.code());

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(db).one(sql.capture(), any(), any(), any());
        assertTrue(sql.getValue().contains("o.partner_id = ?"));
    }

    @Test
    void acceptMovesOnlyAssignedOrdersAndRecordsAnEvent() {
        when(current.partnerId()).thenReturn(PARTNER_ID);
        doAnswer(invocation -> {
            ((Runnable) invocation.getArgument(0)).run();
            return null;
        }).when(db).inTx(any(Runnable.class));
        when(db.one(anyString(), any(), any()))
                .thenReturn(Map.of("id", ORDER_ID, "status", "assigned"));

        Map<String, Object> result = service.accept(ORDER_ID);
        assertEquals("accepted", result.get("status"));

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(db).one(sql.capture(), any(), any());
        assertTrue(sql.getValue().contains("partner_id = ?"));
        verify(db).update(anyString(), any(), any());
        verify(db).update(anyString(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void acceptRejectsAnInvalidTransition() {
        when(current.partnerId()).thenReturn(PARTNER_ID);
        doAnswer(invocation -> {
            ((Runnable) invocation.getArgument(0)).run();
            return null;
        }).when(db).inTx(any(Runnable.class));
        when(db.one(anyString(), any(), any()))
                .thenReturn(Map.of("id", ORDER_ID, "status", "delivered"));

        ApiException error = assertThrows(ApiException.class, () -> service.accept(ORDER_ID));
        assertEquals("BAD_ORDER_STATE", error.code());
    }
}
