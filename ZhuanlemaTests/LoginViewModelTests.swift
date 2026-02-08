/**
 * LoginViewModel 单元测试
 *
 * 覆盖场景：
 * 1. 手机号格式校验
 * 2. 验证码格式校验
 * 3. canSendCode / canLogin 状态计算
 */
import XCTest
@testable import Zhuanlema

final class LoginViewModelTests: XCTestCase {

    @MainActor
    func test_isPhoneNumberValid_with_valid_number() {
        let vm = LoginViewModel()
        vm.phoneNumber = "13800138000"
        XCTAssertTrue(vm.isPhoneNumberValid)
    }

    @MainActor
    func test_isPhoneNumberValid_with_short_number() {
        let vm = LoginViewModel()
        vm.phoneNumber = "1380013"
        XCTAssertFalse(vm.isPhoneNumberValid)
    }

    @MainActor
    func test_isPhoneNumberValid_with_invalid_prefix() {
        let vm = LoginViewModel()
        vm.phoneNumber = "02012345678"
        XCTAssertFalse(vm.isPhoneNumberValid)
    }

    @MainActor
    func test_isCodeValid_with_6_digits() {
        let vm = LoginViewModel()
        vm.verificationCode = "123456"
        XCTAssertTrue(vm.isCodeValid)
    }

    @MainActor
    func test_isCodeValid_with_letters() {
        let vm = LoginViewModel()
        vm.verificationCode = "12345a"
        XCTAssertFalse(vm.isCodeValid)
    }

    @MainActor
    func test_isCodeValid_with_5_digits() {
        let vm = LoginViewModel()
        vm.verificationCode = "12345"
        XCTAssertFalse(vm.isCodeValid)
    }

    @MainActor
    func test_canSendCode_requires_valid_phone_and_no_countdown() {
        let vm = LoginViewModel()
        vm.phoneNumber = "13800138000"
        // countdown == 0, isLoading == false
        XCTAssertTrue(vm.canSendCode)
    }

    @MainActor
    func test_canSendCode_blocked_during_countdown() {
        let vm = LoginViewModel()
        vm.phoneNumber = "13800138000"
        vm.countdown = 30
        XCTAssertFalse(vm.canSendCode)
    }

    @MainActor
    func test_canLogin_requires_all_conditions() {
        let vm = LoginViewModel()
        vm.phoneNumber = "13800138000"
        vm.verificationCode = "123456"
        vm.verificationId = nil
        // verificationId 为 nil，不能登录
        XCTAssertFalse(vm.canLogin)

        vm.verificationId = "test-id"
        XCTAssertTrue(vm.canLogin)
    }

    @MainActor
    func test_canLogin_blocked_when_loading() {
        let vm = LoginViewModel()
        vm.phoneNumber = "13800138000"
        vm.verificationCode = "123456"
        vm.verificationId = "test-id"
        vm.isLoading = true
        XCTAssertFalse(vm.canLogin)
    }
}
