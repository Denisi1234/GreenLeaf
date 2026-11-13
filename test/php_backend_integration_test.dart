import 'package:flutter_test/flutter_test.dart';
import 'package:track_mauzo/service/php_api_client.dart';
import 'package:track_mauzo/service/pos_cloud_database.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/ui/models/customer_data.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/products/inventory_product_item.dart';

void main() {
  const endpoint = String.fromEnvironment('API_TEST_URL');

  test('cloud store completes sales and manages shared data and staff accounts',
      () async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final api = PhpApiClient(endpoint);
    final secondApi = PhpApiClient(endpoint);
    final staffApi = PhpApiClient(endpoint);
    final email = 'integration-$suffix@example.test';
    const password = 'Integration-password-123';
    PosLocalStore? owner;
    PosLocalStore? second;
    PosLocalStore? cashier;
    try {
      await api.authenticate(email: email, password: password, register: true,
        name: 'Owner', storeName: 'Integration shop');
      owner = PosLocalStore(database: PosCloudDatabase(api));
      await owner.initialize();
      expect(owner.inventory, isEmpty);
      expect(owner.cartItems, isEmpty);
      await owner.addProduct(const InventoryProductItem(
        code: 'P1', name: 'Water', category: 'Drinks', purchasePrice: 6,
        sellingPrice: 10, stockCount: 3,
        stockState: InventoryStockState.lowStock, artType: ProductArtType.aquafina,
      ));
      await owner.addCustomer(CustomerData(
        id: 'C1', name: 'Asha', email: '', phone: '0700000000',
        address: '', debitBalance: 0, createdAt: DateTime.now(), tags: [],
      ));
      final sale = await owner.completeCashSale(
        items: [OrderLineItem(product: owner.products.single, quantity: 2)],
        cashTendered: 0, cashierName: 'Ignored', registerName: 'Till 1',
        customerName: 'Asha', paymentMethod: 'Credit',
      );
      expect(sale.cashierName, 'Owner');
      expect(owner.inventory.single.stockCount, 1);
      expect(owner.customers.single.debitBalance, 20);
      await owner.voidOrder(sale.id);
      expect(owner.inventory.single.stockCount, 3);
      expect(owner.customers.single.debitBalance, 0);

      await secondApi.authenticate(email: email, password: password, register: false);
      second = PosLocalStore(database: PosCloudDatabase(secondApi));
      await second.initialize();
      expect(second.inventory.single.code, 'P1');
      await owner.updateProduct(owner.inventory.single.copyWith(stockCount: 4));
      await expectLater(
        second.updateProduct(second.inventory.single.copyWith(stockCount: 8)),
        throwsA(isA<ApiException>()),
      );
      await second.refreshFromServer();
      expect(second.inventory.single.stockCount, 4);
      final staffEmail = 'cashier-$suffix@example.test';
      final staff = await owner.addStaffMember(
        name: 'Cashier', email: staffEmail, phone: '0700000001',
        roleId: owner.staffRoles.last.id, username: 'cashier-$suffix',
        password: password,
      );
      await staffApi.authenticate(email: staffEmail, password: password, register: false);
      cashier = PosLocalStore(database: PosCloudDatabase(staffApi));
      await cashier.initialize();
      expect(cashier.inventory.single.stockCount, 4);
      await expectLater(cashier.updateProduct(
        cashier.inventory.single.copyWith(stockCount: 100)),
        throwsA(isA<ApiException>()),
      );
      await owner.setStaffStatus(staff.id, StaffStatus.inactive);
      await expectLater(staffApi.request('GET', 'auth/me'), throwsA(isA<ApiException>()));
    } finally {
      owner?.dispose();
      second?.dispose();
      cashier?.dispose();
      api.close();
      secondApi.close();
      staffApi.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)),
    skip: endpoint.isEmpty ? 'Set API_TEST_URL to an isolated PHP test server.' : false);
}
